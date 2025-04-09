import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';

/// 관리자용 홈 화면
class AdminHomeScreen extends ConsumerWidget {
  /// 기본 생성자
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('관리자용 대시보드 화면 (임시)', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
