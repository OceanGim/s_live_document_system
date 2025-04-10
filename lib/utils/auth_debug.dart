import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 인증 디버깅 유틸리티
class AuthDebug {
  /// 현재 인증 상태 로깅
  static void logAuthState(WidgetRef ref) {
    final authState = ref.read(authProvider);
    final session = Supabase.instance.client.auth.currentSession;

    Logger.debug('== 인증 상태 디버깅 정보 ==', tag: 'AuthDebug');
    Logger.debug('로그인 상태: ${authState.isLoggedIn}', tag: 'AuthDebug');
    Logger.debug('사용자 ID: ${authState.userId}', tag: 'AuthDebug');
    Logger.debug('사용자 역할: ${authState.userRole}', tag: 'AuthDebug');
    Logger.debug('오류 메시지: ${authState.errorMessage}', tag: 'AuthDebug');

    if (session != null) {
      Logger.debug('세션 만료: ${session.expiresAt}', tag: 'AuthDebug');
      Logger.debug('세션 활성화: ${!session.isExpired}', tag: 'AuthDebug');
    } else {
      Logger.debug('세션: null', tag: 'AuthDebug');
    }
  }

  /// 디버그 팝업 표시
  static void showDebugPopup(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('인증 디버그 정보'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('로그인 상태: ${authState.isLoggedIn}'),
                  Text('사용자 ID: ${authState.userId ?? "없음"}'),
                  Text('사용자 역할: ${authState.userRole ?? "없음"}'),
                  Text('오류: ${authState.errorMessage ?? "없음"}'),
                  const Divider(),
                  ElevatedButton(
                    onPressed: () async {
                      // 사용자 역할 강제 재조회 - 세션 재설정으로 역할 업데이트
                      final session =
                          Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        // 로그아웃 후 세션으로 다시 로그인하여 역할 업데이트 트리거
                        await Supabase.instance.client.auth.refreshSession();
                        Logger.debug('세션 새로고침 완료', tag: 'AuthDebug');
                      }
                      Navigator.of(context).pop();
                      showDebugPopup(context, ref); // 새로운 정보로 다시 표시
                    },
                    child: const Text('역할 재조회'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ],
          ),
    );
  }
}
