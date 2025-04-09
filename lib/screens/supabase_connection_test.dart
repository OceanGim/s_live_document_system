import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 연결 테스트 화면 Provider
final supabaseConnectionStateProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  try {
    // 현재 상태 확인
    final result = <String, dynamic>{
      'initialized': false,
      'connected': false,
      'url': '',
      'anon_key': '',
      'error': null,
      'stack': null,
      'tables': <String>[],
    };

    try {
      // Supabase 인스턴스 가져오기 시도
      final supabase = Supabase.instance;
      result['initialized'] = true;

      // URL 정보 저장
      result['url'] = supabase.client.toString().split('@')[0];

      // 토큰 정보 (일부만 표시)
      try {
        final session = supabase.client.auth.currentSession;
        if (session != null && session.accessToken.isNotEmpty) {
          final token = session.accessToken;
          result['anon_key'] =
              '${token.substring(0, min(10, token.length))}...${token.substring(max(0, token.length - 5))}';
        } else {
          result['anon_key'] = '(인증 토큰 없음)';
        }
      } catch (e) {
        result['anon_key'] = '(토큰 확인 불가)';
        Logger.warning('토큰 정보 접근 실패: $e', tag: 'SupabaseTest');
      }

      // 간단한 쿼리로 연결 테스트 (Supabase 초기화만 확인)
      try {
        // Supabase가 초기화되었다면 연결된 것으로 간주
        // 세션이 없어도 연결은 성공한 것으로 처리
        final response = await supabase.client
            .from('public_users')
            .select('*')
            .limit(1);
        result['connected'] = true;
        Logger.info('Supabase 연결 테스트 성공 (테이블 쿼리)', tag: 'SupabaseTest');
      } catch (e, stack) {
        try {
          // 테이블 쿼리 실패시 단순 Ping을 통해 연결 확인
          await supabase.client.auth.signUp(
            email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
            password: 'test_password',
            emailRedirectTo: null,
          );
          result['connected'] = true;
          Logger.info('Supabase 연결 테스트 성공 (Auth 서비스)', tag: 'SupabaseTest');
        } catch (authError, authStack) {
          if (authError.toString().contains('Email') ||
              authError.toString().contains('Rate limit')) {
            // 이메일 포맷 오류나 레이트 리밋 오류는 실제로 서버에 연결된 것으로 간주
            result['connected'] = true;
            Logger.info('Supabase 연결 테스트 성공 (서버 응답 확인)', tag: 'SupabaseTest');
          } else {
            result['connected'] = false;
            result['error'] = 'API 오류: ${authError.toString()}';
            result['stack'] = authStack.toString();
            Logger.error(
              'Supabase 연결 테스트 실패',
              error: authError,
              tag: 'SupabaseTest',
            );
          }
        }
      }

      // 테이블 목록은 하드코딩 (항상 표시)
      result['tables'] = [
        'public_users',
        'rental_requests',
        'equipment_rentals',
        'survey_responses',
        'user_signatures',
      ];
    } catch (e, stack) {
      result['error'] = e.toString();
      result['stack'] = stack.toString();
      Logger.error('Supabase 인스턴스 접근 실패', error: e, tag: 'SupabaseTest');
    }

    return result;
  } catch (e, stack) {
    Logger.error('Supabase 연결 테스트 기능 에러', error: e, tag: 'SupabaseTest');
    return {
      'initialized': false,
      'connected': false,
      'error': e.toString(),
      'stack': stack.toString(),
    };
  }
});

/// Supabase 연결 테스트 화면
class SupabaseConnectionTestScreen extends ConsumerWidget {
  const SupabaseConnectionTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(supabaseConnectionStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase 연결 상태 확인'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(supabaseConnectionStateProvider);
            },
          ),
        ],
      ),
      body: connectionState.when(
        data: (data) => _buildConnectionInfo(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류 발생: $error')),
      ),
    );
  }

  Widget _buildConnectionInfo(BuildContext context, Map<String, dynamic> data) {
    final isInitialized = data['initialized'] ?? false;
    final isConnected = data['connected'] ?? false;
    final error = data['error'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(
            context,
            title: 'Supabase 초기화 상태',
            status: isInitialized ? '성공' : '실패',
            color: isInitialized ? Colors.green : Colors.red,
            icon: isInitialized ? Icons.check_circle : Icons.error,
          ),
          const SizedBox(height: 16),
          _buildStatusCard(
            context,
            title: 'Supabase 연결 상태',
            status: isConnected ? '성공' : '실패',
            color: isConnected ? Colors.green : Colors.red,
            icon: isConnected ? Icons.check_circle : Icons.error,
          ),
          const SizedBox(height: 16),
          if (data['url'] != null && data['url'].toString().isNotEmpty)
            _buildInfoCard(
              context,
              title: 'Supabase URL',
              content: data['url'].toString(),
            ),
          if (data['anon_key'] != null &&
              data['anon_key'].toString().isNotEmpty)
            _buildInfoCard(
              context,
              title: 'Supabase 토큰 정보',
              content: data['anon_key'].toString(),
            ),
          const SizedBox(height: 16),
          if (error != null)
            _buildErrorCard(
              context,
              error.toString(),
              data['stack']?.toString(),
            ),
          const SizedBox(height: 16),
          if (data['tables'] != null && (data['tables'] as List).isNotEmpty)
            _buildTablesList(context, data['tables'] as List),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String title,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: Text(
                content,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error, String? stack) {
    return Card(
      elevation: 3,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  '오류 정보',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: Text(
                error,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            if (stack != null) ...[
              const SizedBox(height: 8),
              Text(
                '스택 트레이스',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                height: 200,
                child: SingleChildScrollView(
                  child: Text(
                    stack,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTablesList(BuildContext context, List tables) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '테이블 목록',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...tables.map(
              (table) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, size: 20),
                    const SizedBox(width: 8),
                    Text(table.toString()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
