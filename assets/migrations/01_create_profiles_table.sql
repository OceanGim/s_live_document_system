-- Create profiles table for role-based authentication
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  role text default 'user' not null check (role in ('user', 'admin')),
  email text,
  display_name text,
  phone text,
  user_type text,
  company_name text,
  is_email_confirmed boolean default false,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

-- Create a trigger to update the updated_at column
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger handle_profiles_updated_at
before update on public.profiles
for each row execute procedure public.handle_updated_at();

-- Create RLS (Row Level Security) policies for the profiles table
alter table public.profiles enable row level security;

-- Policy for users to view their own profile
create policy "Users can view their own profile"
on public.profiles for select
using (auth.uid() = id);

-- Policy for users to update their own profile
create policy "Users can update their own profile"
on public.profiles for update
using (auth.uid() = id);

-- Policy for admins to view all profiles
create policy "Admins can view all profiles"
on public.profiles for select
using (
  exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  )
);

-- Policy for admins to update all profiles
create policy "Admins can update all profiles"
on public.profiles for update
using (
  exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  )
);

-- Create a trigger to automatically create a profile when a user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'user');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Function to check if a user is an admin
create or replace function public.is_admin()
returns boolean as $$
begin
  return exists(
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
end;
$$ language plpgsql security definer;

-- Create a view for public_users that combines profiles with additional user data
create or replace view public.public_users as
select 
  p.id as user_id,
  p.email,
  p.display_name,
  p.phone,
  p.user_type,
  p.role,
  p.company_name,
  p.is_email_confirmed,
  p.created_at
from public.profiles p;

-- RLS policies for the public_users view
alter view public.public_users set (security_invoker = on);

-- Create a function to make a user an admin
create or replace function public.make_admin(user_id uuid)
returns void as $$
begin
  update public.profiles
  set role = 'admin'
  where id = user_id;
end;
$$ language plpgsql security definer;

-- Create documents table for document management
create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  title text not null,
  content jsonb,
  status text default 'draft' not null,
  document_type text not null,
  metadata jsonb,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  submitted_at timestamp with time zone
);

-- RLS policies for documents
alter table public.documents enable row level security;

-- Users can read their own documents
create policy "Users can view their own documents"
on public.documents for select
using (auth.uid() = user_id);

-- Users can insert their own documents
create policy "Users can create their own documents"
on public.documents for insert
with check (auth.uid() = user_id);

-- Users can update their own documents
create policy "Users can update their own documents"
on public.documents for update
using (auth.uid() = user_id);

-- Admins can read all documents
create policy "Admins can view all documents"
on public.documents for select
using (
  exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  )
);

-- Admins can update all documents
create policy "Admins can update all documents"
on public.documents for update
using (
  exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  )
);

-- Add updated_at trigger for documents
create trigger handle_documents_updated_at
before update on public.documents
for each row execute procedure public.handle_updated_at();
