import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/main.dart';
import 'package:s_live_document_system/screens/database/database_browser_screen.dart';
import 'package:s_live_document_system/utils/supabase_test.dart';

/// Supabase 연결 테스트 화면
class SupabaseTestScreen extends ConsumerWidget {
  /// 기본 생성자
  const SupabaseTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase 연결 테스트'),
        actions: [
          // 테스트 모드 종료 버튼
          TextButton.icon(
            onPressed: () {
              ref.read(showSupabaseTestProvider.notifier).state = false;
            },
            icon: const Icon(Icons.exit_to_app),
            label: const Text('테스트 종료'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: SupabaseTest.buildTestWidget(context)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DatabaseBrowserScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.storage),
              label: const Text('데이터베이스 브라우저 열기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
