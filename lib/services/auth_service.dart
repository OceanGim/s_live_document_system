import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // First, sign up the user in Authentication service
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // Check if there's an error in auth signup
      if (authResponse.user == null) {
        return AuthResponse(
          error: AuthError(message: 'Failed to create user account.'),
        );
      }

      // Create profile with role in the public_users table
      try {
        // Add the role and extra userData to the public_users table
        final userId = authResponse.user!.id;
        final profile = {'user_id': userId, 'role': role, ...userData};

        await _supabase.from('public_users').insert(profile);

        return AuthResponse(
          session: authResponse.session,
          user: authResponse.user,
        );
      } catch (e) {
        // If profile creation fails, we should ideally clean up the auth user,
        // but for simplicity, we'll just return error
        print('Error creating user profile: $e');
        return AuthResponse(
          error: AuthError(
            message: 'Account created but failed to set user role.',
          ),
        );
      }
    } on AuthException catch (e) {
      return AuthResponse(error: AuthError(message: e.message));
    } catch (e) {
      print('Unexpected signup error: $e');
      return AuthResponse(
        error: AuthError(
          message: 'An unexpected error occurred during signup.',
        ),
      );
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return AuthResponse(session: response.session, user: response.user);
    } on AuthException catch (e) {
      return AuthResponse(error: AuthError(message: e.message));
    } catch (e) {
      return AuthResponse(
        error: AuthError(message: 'An unexpected error occurred.'),
      );
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

class AuthResponse {
  final Session? session;
  final User? user;
  final AuthError? error;

  AuthResponse({this.session, this.user, this.error});

  bool get success => error == null;
  String? get message => error?.message;
}

class AuthError {
  final String message;

  AuthError({required this.message});
}
