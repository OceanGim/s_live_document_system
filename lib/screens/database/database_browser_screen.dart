import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:s_live_document_system/utils/supabase_mcp_handler.dart';

/// 데이터베이스 테이블과 데이터를 탐색하는 화면
class DatabaseBrowserScreen extends ConsumerStatefulWidget {
  /// 기본 생성자
  const DatabaseBrowserScreen({super.key});

  @override
  ConsumerState<DatabaseBrowserScreen> createState() =>
      _DatabaseBrowserScreenState();
}

class _DatabaseBrowserScreenState extends ConsumerState<DatabaseBrowserScreen> {
  String? _selectedTable;
  List<Map<String, dynamic>>? _tableData;
  List<Map<String, dynamic>>? _columnData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 초기 데이터 로드
  Future<void> _loadData() async {
    try {
      final tables = await SupabaseMcpHandler.listAllTables();
      if (tables.isNotEmpty) {
        setState(() {
          _selectedTable = tables.first;
        });
        await _loadTableColumns();
        await _loadTableData();
      }
    } catch (e) {
      Logger.error('데이터 로드 실패', error: e);
    }
  }

  /// 선택된 테이블의 컬럼 정보 로드
  Future<void> _loadTableColumns() async {
    if (_selectedTable == null) return;

    try {
      final columns = await SupabaseMcpHandler.getTableColumns(_selectedTable!);
      setState(() {
        _columnData = columns;
      });
    } catch (e) {
      Logger.error('컬럼 정보 로드 실패', error: e);
    }
  }

  /// 선택된 테이블의 데이터 로드
  Future<void> _loadTableData() async {
    if (_selectedTable == null) return;

    try {
      final data = await SupabaseMcpHandler.getTableData(
        _selectedTable!,
        limit: 20,
      );
      setState(() {
        _tableData = data;
      });
    } catch (e) {
      Logger.error('테이블 데이터 로드 실패', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsyncValue = ref.watch(supabaseTablesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('데이터베이스 브라우저')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 테이블 선택 드롭다운
            tablesAsyncValue.when(
              data: (tables) => _buildTableSelector(tables),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('테이블 목록 로드 실패: $error'),
            ),

            const SizedBox(height: 16),

            // 테이블 컬럼 정보
            if (_columnData != null && _columnData!.isNotEmpty)
              _buildColumnInfo(),

            const SizedBox(height: 16),

            // 테이블 데이터
            if (_tableData != null) Expanded(child: _buildDataTable()),
          ],
        ),
      ),
    );
  }

  /// 테이블 선택 드롭다운 위젯
  Widget _buildTableSelector(List<String> tables) {
    return Row(
      children: [
        const Text('테이블 선택: ', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _selectedTable,
          items:
              tables.map((table) {
                return DropdownMenuItem<String>(
                  value: table,
                  child: Text(table),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null && value != _selectedTable) {
              setState(() {
                _selectedTable = value;
                _tableData = null;
                _columnData = null;
              });
              _loadTableColumns();
              _loadTableData();
            }
          },
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {
            _loadTableData();
            _loadTableColumns();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('새로고침'),
        ),
      ],
    );
  }

  /// 컬럼 정보를 보여주는 위젯
  Widget _buildColumnInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_selectedTable} 컬럼 정보:',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('컬럼명')),
                  DataColumn(label: Text('데이터 타입')),
                  DataColumn(label: Text('Null 허용')),
                ],
                rows:
                    _columnData!.map((column) {
                      return DataRow(
                        cells: [
                          DataCell(Text(column['column_name'] ?? '')),
                          DataCell(Text(column['data_type'] ?? '')),
                          DataCell(
                            Text(column['is_nullable'] == 'YES' ? '허용' : '불가'),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 테이블 데이터를 보여주는 위젯
  Widget _buildDataTable() {
    if (_tableData == null || _tableData!.isEmpty) {
      return const Center(child: Text('데이터가 없거나 로드할 수 없습니다.'));
    }

    // 모든 컬럼 추출
    final columns = _tableData!.first.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_selectedTable} 데이터 (${_tableData!.length}건):',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns:
                    columns.map((column) {
                      return DataColumn(
                        label: Text(
                          column,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                rows:
                    _tableData!.map((row) {
                      return DataRow(
                        cells:
                            columns.map((column) {
                              final value = row[column];
                              return DataCell(
                                Text(value?.toString() ?? 'null'),
                              );
                            }).toList(),
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
