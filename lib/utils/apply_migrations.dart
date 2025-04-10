import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:s_live_document_system/utils/logger.dart';

/// 데이터베이스 마이그레이션을 적용하는 유틸리티 클래스
class MigrationExecutor {
  final SupabaseClient _supabase;
  final BuildContext? context; // SnackBar 표시용 (선택 사항)

  MigrationExecutor(this._supabase, {this.context});

  /// RLS 및 사용자 권한 관련 문제 해결을 위한 마이그레이션 적용
  Future<bool> applyAuthFixMigrations() async {
    try {
      Logger.info('사용자 권한 관련 마이그레이션 시작...', tag: 'MigrationExecutor');

      // 1. get_user_role 함수 생성/재정의
      final getUserRoleResult = await _supabase.rpc(
        'create_or_replace_function_sql',
        params: {
          'function_sql': '''
          CREATE OR REPLACE FUNCTION get_user_role(user_id_param UUID)
          RETURNS TEXT
          LANGUAGE plpgsql
          SECURITY DEFINER
          AS \$\$
          DECLARE
            role_val TEXT;
          BEGIN
            SELECT role INTO role_val 
            FROM public_users 
            WHERE user_id = user_id_param;
            
            RETURN COALESCE(role_val, 'user');
          END;
          \$\$;
          ''',
        },
      );
      Logger.info(
        'get_user_role 함수 생성 결과: $getUserRoleResult',
        tag: 'MigrationExecutor',
      );

      // 2. 함수 권한 설정
      await _supabase.rpc(
        'execute_sql',
        params: {
          'sql_query': '''
          REVOKE ALL ON FUNCTION get_user_role(UUID) FROM PUBLIC;
          GRANT EXECUTE ON FUNCTION get_user_role(UUID) TO authenticated;
          GRANT EXECUTE ON FUNCTION get_user_role(UUID) TO anon;
          ''',
        },
      );
      Logger.info('함수 권한 설정 완료', tag: 'MigrationExecutor');

      // 3. public_users 테이블에 RLS 정책 재설정
      // 먼저 RLS 활성화
      await _supabase.rpc(
        'execute_sql',
        params: {
          'sql_query': 'ALTER TABLE public_users ENABLE ROW LEVEL SECURITY;',
        },
      );

      // 기존 정책 삭제 (오류가 발생할 수 있으므로 무시)
      try {
        await _supabase.rpc(
          'execute_sql',
          params: {
            'sql_query': '''
            DROP POLICY IF EXISTS "Users can view their own profiles" ON public_users;
            DROP POLICY IF EXISTS "Users can update their own profiles" ON public_users;
            DROP POLICY IF EXISTS "Admins can view all profiles" ON public_users;
            DROP POLICY IF EXISTS "Admins can update all profiles" ON public_users;
            ''',
          },
        );
      } catch (e) {
        Logger.warning('기존 정책 삭제 중 오류 (무시됨): $e', tag: 'MigrationExecutor');
      }

      // 새 정책 생성
      await _supabase.rpc(
        'execute_sql',
        params: {
          'sql_query': '''
          -- 사용자는 자신의 정보만 볼 수 있음
          CREATE POLICY "Users can view their own profiles" ON public_users
          FOR SELECT 
          USING (auth.uid() = user_id);

          -- 사용자는 자신의 정보만 업데이트할 수 있음
          CREATE POLICY "Users can update their own profiles" ON public_users
          FOR UPDATE
          USING (auth.uid() = user_id);

          -- 관리자는 모든 사용자의 정보를 볼 수 있음
          CREATE POLICY "Admins can view all profiles" ON public_users
          FOR SELECT
          USING (
            EXISTS (
              SELECT 1 FROM public_users 
              WHERE user_id = auth.uid() AND role = 'admin'
            )
          );

          -- 관리자는 모든 사용자의 정보를 업데이트할 수 있음
          CREATE POLICY "Admins can update all profiles" ON public_users
          FOR UPDATE
          USING (
            EXISTS (
              SELECT 1 FROM public_users 
              WHERE user_id = auth.uid() AND role = 'admin'
            )
          );
          ''',
        },
      );
      Logger.info('RLS 정책 설정 완료', tag: 'MigrationExecutor');

      // 성공 메시지 표시 (선택 사항)
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          const SnackBar(
            content: Text('사용자 권한 관련 마이그레이션이 성공적으로 적용되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } catch (e) {
      Logger.error('마이그레이션 적용 중 오류 발생', error: e, tag: 'MigrationExecutor');

      // 오류 메시지 표시 (선택 사항)
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(content: Text('마이그레이션 실패: $e'), backgroundColor: Colors.red),
        );
      }

      return false;
    }
  }

  /// 테스트 계정 설정을 위한 마이그레이션
  Future<bool> setupTestAccounts() async {
    try {
      Logger.info('테스트 계정 설정 시작...', tag: 'MigrationExecutor');

      // 1. 관리자 계정이 존재하는지 확인
      final adminExists =
          await _supabase
              .from('public_users')
              .select('email')
              .eq('email', 'admin@slive.com')
              .maybeSingle();

      // 관리자 계정이 없으면 생성
      if (adminExists == null) {
        Logger.info('관리자 계정 생성 중...', tag: 'MigrationExecutor');

        // 먼저 auth 서비스에 사용자 생성 (이미 있으면 오류 발생할 수 있음)
        try {
          await _supabase.auth.admin.createUser(
            AdminUserAttributes(
              email: 'admin@slive.com',
              password: 'admin123',
              emailConfirm: true,
            ),
          );
        } catch (e) {
          Logger.warning(
            'Auth 서비스에 관리자 생성 중 오류 (이미 존재할 수 있음): $e',
            tag: 'MigrationExecutor',
          );
        }

        // 사용자 ID 조회
        final adminUsersResult = await _supabase.auth.admin.listUsers();
        final adminUserId =
            (adminUsersResult as List).firstWhere(
              (user) => user['email'] == 'admin@slive.com',
              orElse: () => throw Exception('관리자 사용자 ID를 찾을 수 없습니다.'),
            )['id'];

        // public_users 테이블에 관리자 정보 저장
        await _supabase.from('public_users').upsert({
          'user_id': adminUserId,
          'email': 'admin@slive.com',
          'role': 'admin',
          'display_name': '관리자',
        });

        Logger.info('관리자 계정 생성 완료', tag: 'MigrationExecutor');
      }

      // 2. 일반 사용자 계정이 존재하는지 확인
      final userExists =
          await _supabase
              .from('public_users')
              .select('email')
              .eq('email', 'user@example.com')
              .maybeSingle();

      // 일반 사용자 계정이 없으면 생성
      if (userExists == null) {
        Logger.info('일반 사용자 계정 생성 중...', tag: 'MigrationExecutor');

        // 먼저 auth 서비스에 사용자 생성 (이미 있으면 오류 발생할 수 있음)
        try {
          await _supabase.auth.admin.createUser(
            AdminUserAttributes(
              email: 'user@example.com',
              password: 'user123',
              emailConfirm: true,
            ),
          );
        } catch (e) {
          Logger.warning(
            'Auth 서비스에 일반 사용자 생성 중 오류 (이미 존재할 수 있음): $e',
            tag: 'MigrationExecutor',
          );
        }

        // 사용자 ID 조회
        final normalUsersResult = await _supabase.auth.admin.listUsers();
        final normalUserId =
            (normalUsersResult as List).firstWhere(
              (user) => user['email'] == 'user@example.com',
              orElse: () => throw Exception('일반 사용자 ID를 찾을 수 없습니다.'),
            )['id'];

        // public_users 테이블에 일반 사용자 정보 저장
        await _supabase.from('public_users').upsert({
          'user_id': normalUserId,
          'email': 'user@example.com',
          'role': 'user',
          'display_name': '일반 사용자',
        });

        Logger.info('일반 사용자 계정 생성 완료', tag: 'MigrationExecutor');
      }

      // 성공 메시지 표시 (선택 사항)
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          const SnackBar(
            content: Text('테스트 계정 설정이 성공적으로 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } catch (e) {
      Logger.error('테스트 계정 설정 중 오류 발생', error: e, tag: 'MigrationExecutor');

      // 오류 메시지 표시 (선택 사항)
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text('테스트 계정 설정 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    }
  }
}
