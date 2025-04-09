import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:s_live_document_system/utils/logger.dart';

/// Supabase 연결 테스트를 위한 유틸리티 클래스
class SupabaseTest {
  /// Supabase 연결 테스트
  static Future<bool> testConnection() async {
    try {
      Logger.info('Supabase 연결 테스트 시작', tag: 'SupabaseTest');

      try {
        // Supabase 초기화 여부를 간접적으로 확인
        // isInitialized 멤버가 없으므로 예외 처리로 구현
        final _ = Supabase.instance;
      } catch (e) {
        Logger.warning('Supabase가 아직 초기화되지 않았습니다', tag: 'SupabaseTest');
        return false;
      }

      // Supabase 클라이언트 가져오기
      final client = Supabase.instance.client;

      // 간단한 ping 쿼리 실행
      final res = await client.from('public_users').select('count').limit(1);

      final count = res.length;
      Logger.info('Supabase 연결 성공: 사용자 수 $count', tag: 'SupabaseTest');
      return true;
    } catch (e, stack) {
      Logger.error(
        'Supabase 연결 테스트 실패',
        error: e,
        stackTrace: stack,
        tag: 'SupabaseTest',
      );
      return false;
    }
  }

  /// Supabase 테이블 존재 여부 확인
  static Future<List<String>> listTables() async {
    try {
      Logger.info('Supabase 테이블 목록 조회', tag: 'SupabaseTest');

      final client = Supabase.instance.client;

      // PostgreSQL의 information_schema에서 테이블 목록 조회
      final res = await client.rpc(
        'get_schema_info',
        params: {'schema_name': 'public'},
      );

      if (res == null) {
        return [];
      }

      final tables =
          (res as List).map((item) => item['table_name'] as String).toList();
      Logger.info('테이블 목록: $tables', tag: 'SupabaseTest');
      return tables;
    } catch (e, stack) {
      Logger.error(
        'Supabase 테이블 목록 조회 실패',
        error: e,
        stackTrace: stack,
        tag: 'SupabaseTest',
      );
      return [];
    }
  }

  /// 테스트 결과를 보여주는 위젯
  static Widget buildTestWidget(BuildContext context) {
    return FutureBuilder<bool>(
      future: testConnection(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final isConnected = snapshot.data ?? false;

        return Scaffold(
          appBar: AppBar(title: const Text('Supabase 연결 테스트')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error,
                  color: isConnected ? Colors.green : Colors.red,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  isConnected ? 'Supabase 연결 성공!' : 'Supabase 연결 실패',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                if (isConnected)
                  FutureBuilder<List<String>>(
                    future: listTables(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      final tables = snapshot.data ?? [];

                      return Column(
                        children: [
                          Text(
                            '데이터베이스 테이블 (${tables.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (tables.isEmpty)
                            const Text('테이블이 없거나 조회할 수 없습니다.')
                          else
                            Container(
                              height: 200,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                itemCount: tables.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Text('• ${tables[index]}'),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
