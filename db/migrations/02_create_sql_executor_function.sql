-- PostgreSQL 슈퍼 관리자 권한이 필요한 작업입니다.
-- 이 파일은 Supabase 대시보드의 SQL 편집기에서 직접 실행해야 합니다.

-- SQL 실행 함수 생성 (관리자만 접근 가능)
CREATE OR REPLACE FUNCTION execute_sql(query text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER -- 함수 생성자의 권한으로 실행
SET search_path = public
AS $$
DECLARE
  result jsonb;
BEGIN
  -- 관리자 권한 확인
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Permission denied: 관리자 권한이 필요합니다';
  END IF;

  -- 쿼리 실행 및 결과 반환 (JSON 형태로)
  EXECUTE query;
  result := jsonb_build_object('status', 'success', 'message', '쿼리가 성공적으로 실행되었습니다.');
  
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'status', 'error',
    'message', SQLERRM,
    'detail', SQLSTATE
  );
END;
$$;

-- 함수에 대한 접근 권한 설정
REVOKE ALL ON FUNCTION execute_sql(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION execute_sql(text) TO authenticated;
