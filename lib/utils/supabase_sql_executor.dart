import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase SQL 실행기
class SupabaseSqlExecutor {
  /// SQL 쿼리 실행
  static Future<Map<String, dynamic>> executeRawSql(String sql) async {
    try {
      Logger.info(
        'SQL 실행 시작: ${sql.substring(0, sql.length > 100 ? 100 : sql.length)}...',
        tag: 'SqlExecutor',
      );

      // Supabase의 rpc 기능을 사용하여 SQL 실행
      final result = await Supabase.instance.client.rpc(
        'execute_sql',
        params: {'query': sql},
      );

      Logger.info('SQL 실행 완료', tag: 'SqlExecutor');
      return {'success': true, 'result': result};
    } catch (e, stack) {
      Logger.error(
        'SQL 실행 실패',
        error: e,
        stackTrace: stack,
        tag: 'SqlExecutor',
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// SQL 스크립트 파일 실행
  static Future<Map<String, dynamic>> executeSqlScript(
    String scriptContent,
  ) async {
    try {
      // SQL 스크립트를 개별 쿼리로 분리
      final List<String> queries = _splitSqlScript(scriptContent);

      List<Map<String, dynamic>> results = [];
      bool allSuccess = true;
      String firstError = '';

      // 각 쿼리 개별적으로 실행
      for (final query in queries) {
        final trimmedQuery = query.trim();
        if (trimmedQuery.isEmpty) continue;

        try {
          final result = await executeRawSql(trimmedQuery);
          results.add({
            'query':
                trimmedQuery.substring(
                  0,
                  trimmedQuery.length > 50 ? 50 : trimmedQuery.length,
                ) +
                '...',
            'success': result['success'],
            'result': result['success'] ? result['result'] : result['error'],
          });

          if (!result['success'] && allSuccess) {
            allSuccess = false;
            firstError = result['error'];
          }
        } catch (e) {
          results.add({
            'query':
                trimmedQuery.substring(
                  0,
                  trimmedQuery.length > 50 ? 50 : trimmedQuery.length,
                ) +
                '...',
            'success': false,
            'result': e.toString(),
          });

          if (allSuccess) {
            allSuccess = false;
            firstError = e.toString();
          }
        }
      }

      return {
        'success': allSuccess,
        'results': results,
        'error': allSuccess ? '' : firstError,
      };
    } catch (e, stack) {
      Logger.error(
        'SQL 스크립트 실행 실패',
        error: e,
        stackTrace: stack,
        tag: 'SqlExecutor',
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// SQL 스크립트를 개별 쿼리로 분리
  static List<String> _splitSqlScript(String script) {
    // SQL 주석 제거
    final noComments = script.replaceAll(RegExp(r'--.*'), '');

    // 세미콜론으로 구분된 쿼리 분리
    return noComments
        .split(';')
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();
  }
}

/// SQL 실행 화면
class SqlExecutorScreen extends ConsumerStatefulWidget {
  /// 기본 생성자
  const SqlExecutorScreen({super.key, this.initialSql = ''});

  /// 초기 SQL
  final String initialSql;

  @override
  ConsumerState<SqlExecutorScreen> createState() => _SqlExecutorScreenState();
}

class _SqlExecutorScreenState extends ConsumerState<SqlExecutorScreen> {
  final TextEditingController _sqlController = TextEditingController();
  final ScrollController _resultScrollController = ScrollController();
  bool _isExecuting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _sqlController.text = widget.initialSql;
  }

  @override
  void dispose() {
    _sqlController.dispose();
    _resultScrollController.dispose();
    super.dispose();
  }

  /// SQL 실행
  Future<void> _executeQuery() async {
    final sql = _sqlController.text.trim();
    if (sql.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SQL을 입력해주세요.')));
      return;
    }

    setState(() {
      _isExecuting = true;
      _result = null;
    });

    try {
      final result = await SupabaseSqlExecutor.executeSqlScript(sql);

      if (mounted) {
        setState(() {
          _isExecuting = false;
          _result = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _result = {'success': false, 'error': e.toString()};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SQL 실행기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: '마이그레이션 스크립트 불러오기',
            onPressed: _loadMigrationScript,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'SQL 실행',
            onPressed: _isExecuting ? null : _executeQuery,
          ),
        ],
      ),
      body: Column(
        children: [
          // SQL 입력 영역
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _sqlController,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'SQL 쿼리 입력...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),

          // 구분선
          const Divider(height: 1),

          // 실행 결과 영역
          Expanded(flex: 3, child: _buildResultView()),
        ],
      ),
    );
  }

  /// 마이그레이션 스크립트 불러오기
  Future<void> _loadMigrationScript() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('스크립트 선택'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('테이블 및 RLS 정책 생성'),
                  subtitle: const Text('01_create_profiles_table.sql'),
                  onTap: () async {
                    try {
                      final migrationContent = await DefaultAssetBundle.of(
                        context,
                      ).loadString(
                        'db/migrations/01_create_profiles_table.sql',
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                        setState(() {
                          _sqlController.text = migrationContent;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('파일 로드 실패: ${e.toString()}')),
                        );
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
                ListTile(
                  title: const Text('관리자 권한 부여'),
                  subtitle: const Text('특정 사용자를 관리자로 설정'),
                  onTap: () {
                    final currentUser =
                        Supabase.instance.client.auth.currentUser;
                    if (currentUser != null) {
                      Navigator.of(context).pop();
                      setState(() {
                        _sqlController.text = '''
-- 현재 로그인한 사용자를 관리자로 설정
UPDATE public.profiles
SET role = 'admin'
WHERE id = '${currentUser.id}';
''';
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('로그인이 필요합니다.')),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
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

  /// 실행 결과 표시
  Widget _buildResultView() {
    if (_isExecuting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('SQL 실행 중...'),
          ],
        ),
      );
    }

    if (_result == null) {
      return const Center(child: Text('실행 결과가 여기에 표시됩니다.'));
    }

    return SingleChildScrollView(
      controller: _resultScrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _result!['success'] ? Icons.check_circle : Icons.error,
                color: _result!['success'] ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _result!['success'] ? '실행 성공' : '실행 실패',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _result!['success'] ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (!_result!['success'] && _result!['error'] != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('오류: ${_result!['error']}'),
              ),
            ),

          if (_result!['results'] != null) ...[
            const SizedBox(height: 16),
            const Text('실행 결과:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._result!['results'].map<Widget>((result) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color:
                    result['success']
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('쿼리: ${result['query']}'),
                      const SizedBox(height: 4),
                      Text(
                        '결과: ${result['result']}',
                        style: TextStyle(
                          color:
                              result['success']
                                  ? Colors.green.shade900
                                  : Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
