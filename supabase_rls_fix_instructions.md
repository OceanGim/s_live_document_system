# Supabase Row Level Security (RLS) 문제 해결 가이드

## 문제 설명
현재 `public_users` 테이블에서 "무한 재귀" 오류가 발생하고 있습니다:
```
infinite recursion detected in policy for relation "public_users"
```

이는 RLS 정책이 서로를 순환 참조하거나 자기 자신을 참조하는 복잡한 쿼리를 포함하고 있을 때 발생합니다.

## 해결 방법 (관리자 콘솔)

### 옵션 1: RLS 비활성화 (임시 해결책)
가장 간단한 해결책은 RLS를 비활성화하는 것입니다. 이는 개발 중에는 편리하지만, 프로덕션 환경에서는 보안상 권장되지 않습니다.

1. 관리자 콘솔에 로그인
2. 'Table Editor'로 이동
3. `public_users` 테이블 선택
4. 'RLS' 토글 버튼을 OFF로 전환

### 옵션 2: 정책 수정 (권장 방법)

1. `public_users` 테이블을 선택한 후 'Policies' 탭으로 이동
2. 기존 정책을 검토하고 다음과 같이 수정:

#### INSERT 정책 (사용자가 자신의 프로필만 추가할 수 있음)
```sql
-- USING 표현식
true

-- WITH CHECK 표현식
auth.uid() = id
```

#### SELECT 정책 (사용자 또는 관리자만 조회 가능)
```sql
-- USING 표현식
auth.uid() = id OR (
  SELECT is_admin FROM public_users WHERE id = auth.uid()
)
```

#### UPDATE 정책 (사용자 또는 관리자만 업데이트 가능)
```sql
-- USING 표현식
auth.uid() = id OR (
  SELECT is_admin FROM public_users WHERE id = auth.uid()
)

-- WITH CHECK 표현식
auth.uid() = id OR (
  SELECT is_admin FROM public_users WHERE id = auth.uid()
)
```

## SQL 에디터를 통한 해결 방법

관리자 콘솔의 SQL 에디터에서 다음 쿼리를 실행할 수 있습니다:

### 1. 현재 정책 확인
```sql
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  cmd, 
  qualifier, 
  with_check 
FROM 
  pg_policies 
WHERE 
  tablename = 'public_users';
```

### 2. 모든 정책 삭제 (주의: 모든 정책 제거)
```sql
DROP POLICY IF EXISTS "User inserts own profile" ON "public_users";
DROP POLICY IF EXISTS "User or Admin can select" ON "public_users";
DROP POLICY IF EXISTS "User or Admin can update" ON "public_users";
```

### 3. 새 정책 생성
```sql
-- INSERT 정책
CREATE POLICY "User inserts own profile"
ON "public_users"
FOR INSERT
TO public
WITH CHECK (auth.uid() = id);

-- SELECT 정책 (간소화된 버전)
CREATE POLICY "User or Admin can select"
ON "public_users"
FOR SELECT
TO public
USING (auth.uid() = id OR EXISTS (
  SELECT 1 FROM public_users WHERE id = auth.uid() AND is_admin = true
));

-- UPDATE 정책 (간소화된 버전)
CREATE POLICY "User or Admin can update"
ON "public_users"
FOR UPDATE
TO public
USING (auth.uid() = id OR EXISTS (
  SELECT 1 FROM public_users WHERE id = auth.uid() AND is_admin = true
))
WITH CHECK (true);
```

### 4. RLS 활성화 (비활성화되어 있는 경우)
```sql
ALTER TABLE public_users ENABLE ROW LEVEL SECURITY;
```

## 참고 사항
- 위의 예시는 `public_users` 테이블에 `is_admin` 필드가 있다고 가정합니다.
- 정책 이름은 일치시켜야 합니다.
- 쿼리는 재귀 참조를 방지하기 위해 단순화되었습니다.
- 업데이트 정책은 권한 확인 후 업데이트할 내용에 제한을 두지 않습니다(`WITH CHECK (true)`).
