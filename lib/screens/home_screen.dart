import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/screens/admin/admin_home_screen.dart';
import 'package:s_live_document_system/screens/user/user_home_screen.dart';
import 'package:s_live_document_system/utils/auth_debug.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 인증 상태 디버깅 정보 로깅 및 화면 전환 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });
  }

  // 역할에 따라 적절한 화면으로 자동 이동
  void _checkAndNavigate() {
    AuthDebug.logAuthState(ref);

    final authState = ref.read(authProvider);
    final userRole = authState.userRole;

    Logger.debug('현재 사용자 역할: $userRole', tag: 'HomeScreen');

    // 이메일이 admin@slive.com이면 강제로 관리자 화면으로 이동
    final userEmail = Supabase.instance.client.auth.currentUser?.email;
    if (userEmail != null && userEmail.toLowerCase() == 'admin@slive.com') {
      Logger.debug('관리자 이메일 확인: $userEmail - 관리자 화면으로 이동', tag: 'HomeScreen');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
        );
      });
      return;
    }

    // 역할이 설정되어 있으면 해당 화면으로 이동
    if (userRole != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => _getScreenByRole(userRole)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 강제로 바로 역할에 맞는 화면 표시 (디버그 화면 생략)
    // 이메일 직접 확인하여 admin@slive.com이면 관리자 화면으로 이동
    final userEmail = Supabase.instance.client.auth.currentUser?.email;

    if (userEmail != null && userEmail.toLowerCase() == 'admin@slive.com') {
      // 관리자 화면 직접 반환
      return const AdminHomeScreen();
    } else {
      // 일반 사용자 화면 직접 반환
      return const UserHomeScreen();
    }
  }

  Widget _getScreenByRole(String? userRole) {
    Logger.debug('화면 전환: 역할 = $userRole', tag: 'HomeScreen');
    if (userRole == 'admin') {
      return const AdminHomeScreen();
    } else {
      return const UserHomeScreen();
    }
  }
}
