import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/screens/admin/admin_home_screen.dart';
import 'package:s_live_document_system/screens/user/user_home_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 인증 상태 조회
    final authState = ref.watch(authProvider);
    final userRole = authState.userRole;

    // 사용자 역할에 따라 다른 화면 표시
    if (userRole == 'admin') {
      return const AdminHomeScreen();
    } else {
      return const UserHomeScreen();
    }
  }
}
