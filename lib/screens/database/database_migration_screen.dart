import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:s_live_document_system/utils/supabase_sql_executor.dart';

/// 데이터베이스 마이그레이션 화면
class DatabaseMigrationScreen extends ConsumerStatefulWidget {
  /// 기본 생성자
  const DatabaseMigrationScreen({super.key});

  @override
  ConsumerState<DatabaseMigrationScreen> createState() =>
      _DatabaseMigrationScreenState();
}

class _DatabaseMigrationScreenState
    extends ConsumerState<DatabaseMigrationScreen> {
  bool _isLoading = false;
  List<String> _migrationFiles = [];
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadMigrationFilesList();
  }

  /// 마이그레이션 파일 목록 로드
  Future<void> _loadMigrationFilesList() async {
    try {
      // Flutter 에셋 매니페스트에서 migrations 디렉토리의 파일들을 찾음
      setState(() {
        _migrationFiles = ['assets/migrations/01_create_profiles_table.sql'];
      });
    } catch (e) {
      Logger.error('마이그레이션 파일 목록 로드 실패', error: e, tag: 'DatabaseMigration');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('마이그레이션 파일 목록 로드 실패: ${e.toString()}')),
        );
      }
    }
  }

  /// 마이그레이션 파일 실행
  Future<void> _runMigration(String filePath) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      // 마이그레이션 파일 로드
      final sqlContent = await rootBundle.loadString(filePath);

      // SQL 실행
      final result = await SupabaseSqlExecutor.executeSqlScript(sqlContent);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastResult = result;
        });

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('마이그레이션 성공: ${filePath.split('/').last}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('마이그레이션 실패: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('마이그레이션 실패', error: e, tag: 'DatabaseMigration');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastResult = {'success': false, 'error': e.toString()};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('마이그레이션 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('데이터베이스 마이그레이션'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: _loadMigrationFilesList,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('마이그레이션 실행 중...'),
                    Text('(시간이 다소 소요될 수 있습니다)'),
                  ],
                ),
              )
              : Column(
                children: [
                  // 설명 카드
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '데이터베이스 마이그레이션',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '마이그레이션 파일을 실행하여 데이터베이스 스키마를 설정합니다. '
                            '실행 권한이 있는 사용자 계정으로 로그인해야 합니다.',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '주의: 마이그레이션은 데이터베이스 구조를 변경하는 작업이므로 '
                                  '백업 후 진행하세요.',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 마이그레이션 파일 목록
                  Expanded(
                    child:
                        _migrationFiles.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.info_outline, size: 48),
                                  const SizedBox(height: 16),
                                  const Text('마이그레이션 파일이 없습니다.'),
                                  const SizedBox(height: 32),
                                  ElevatedButton(
                                    onPressed: _loadMigrationFilesList,
                                    child: const Text('새로고침'),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _migrationFiles.length,
                              itemBuilder: (context, index) {
                                final fileName =
                                    _migrationFiles[index].split('/').last;
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: const Icon(Icons.code),
                                    title: Text(fileName),
                                    subtitle: Text(
                                      _getMigrationDescription(fileName),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      tooltip: '실행',
                                      onPressed:
                                          () => _runMigration(
                                            _migrationFiles[index],
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),

                  // 실행 결과
                  if (_lastResult != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            _lastResult!['success']
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _lastResult!['success']
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _lastResult!['success']
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color:
                                      _lastResult!['success']
                                          ? Colors.green
                                          : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _lastResult!['success']
                                      ? '마이그레이션 성공'
                                      : '마이그레이션 실패',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _lastResult!['success']
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (!_lastResult!['success'] &&
                                _lastResult!['error'] != null)
                              Text('오류: ${_lastResult!['error']}'),
                            if (_lastResult!['results'] != null) ...[
                              const SizedBox(height: 16),
                              const Text(
                                '실행 결과:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._lastResult!['results'].map<Widget>((result) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
    );
  }

  /// 마이그레이션 파일 설명 가져오기
  String _getMigrationDescription(String fileName) {
    if (fileName.contains('01_create_profiles_table')) {
      return '테이블 및 RLS 정책 생성 (프로필, 문서, 등)';
    }
    if (fileName.contains('02_create_sql_executor_function')) {
      return 'SQL 실행 함수 생성 (관리자 전용)';
    }
    return '데이터베이스 스키마 변경';
  }
}
