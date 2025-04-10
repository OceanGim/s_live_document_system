import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:s_live_document_system/utils/logger.dart';

/// 관리자 계정 생성 유틸리티
class AdminCreator {
  static final supabase = Supabase.instance.client;

  /// 관리자 계정 생성 및 권한 설정
  static Future<bool> createAdminAccount(
    BuildContext context, {
    required String email,
    required String password,
    String displayName = '관리자',
  }) async {
    try {
      // 1. 사용자 존재 여부 확인
      final existingUsers = await supabase
          .from('public_users')
          .select()
          .eq('email', email)
          .limit(1);

      if (existingUsers.isNotEmpty) {
        // 이미 존재하는 경우 관리자 권한 부여
        final userId = existingUsers[0]['user_id'];
        await supabase
            .from('public_users')
            .update({'role': 'admin'})
            .eq('user_id', userId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기존 사용자에게 관리자 권한이 부여되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      }

      // 2. 계정 생성
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName, 'role': 'admin'},
      );

      // 3. 계정 생성 확인
      if (response.user != null) {
        // 4. 관리자 권한 직접 설정 (RLS 때문에 필요할 수 있음)
        await supabase
            .from('public_users')
            .update({'role': 'admin'})
            .eq('user_id', response.user!.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('관리자 계정이 생성되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정 생성 실패: 응답에 사용자 정보가 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      Logger.error('관리자 계정 생성 실패', error: e, tag: 'AdminCreator');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('관리자 계정 생성 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
}
