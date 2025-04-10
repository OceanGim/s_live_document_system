import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/models/document_model.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/providers/document_provider.dart';
import 'package:s_live_document_system/screens/document/document_detail_screen.dart';

/// 문서 목록 화면
class DocumentListScreen extends ConsumerStatefulWidget {
  /// 기본 생성자
  const DocumentListScreen({super.key});

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen> {
  String _filterDocumentType = '';
  String _filterStatus = '';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.userId;

    // 사용자 ID가 없으면 로그인 안내 문구 표시
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('문서 관리')),
        body: const Center(child: Text('로그인이 필요합니다.')),
      );
    }

    // 필터링 파라미터로 문서 목록 조회
    final filterParams = FilterParams(
      userId: userId,
      documentType: _filterDocumentType,
      status: _filterStatus,
    );
    final filteredDocuments = ref.watch(
      filteredUserDocumentsProvider(filterParams),
    );

    // 전체 문서 목록 조회 (필터 선택용)
    final asyncDocuments = ref.watch(userDocumentsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('문서 관리'),
        actions: [
          // 문서 유형 필터 버튼
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: '문서 유형 필터',
            onSelected: (value) {
              setState(() {
                _filterDocumentType = value;
              });
            },
            itemBuilder: (context) {
              // 사용자의 문서 유형으로 필터 메뉴 구성
              final menuItems = <PopupMenuItem<String>>[
                const PopupMenuItem(value: '', child: Text('모든 문서 유형')),
              ];

              // 비동기 데이터가 로드된 경우에만 처리
              if (asyncDocuments is AsyncData) {
                // 중복 없이 문서 유형 추출
                final documentTypes =
                    asyncDocuments.value!
                        .map((doc) => doc.documentType)
                        .toSet()
                        .toList();

                // 각 문서 유형별 메뉴 아이템 추가
                for (final type in documentTypes) {
                  final typeName =
                      asyncDocuments.value!
                          .firstWhere((doc) => doc.documentType == type)
                          .documentTypeName;

                  menuItems.add(
                    PopupMenuItem(value: type, child: Text(typeName)),
                  );
                }
              }

              return menuItems;
            },
          ),
          // 상태 필터 버튼
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            tooltip: '상태 필터',
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: '', child: Text('모든 상태')),
                  const PopupMenuItem(value: 'submitted', child: Text('제출 완료')),
                  const PopupMenuItem(value: 'pending', child: Text('대기 중')),
                  const PopupMenuItem(value: 'missing', child: Text('미제출')),
                ],
          ),
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: () {
              ref.refresh(userDocumentsProvider(userId));
            },
          ),
        ],
      ),
      // 문서 생성 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 새 문서 작성 화면으로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('새 문서 생성 기능은 아직 구현되지 않았습니다.')),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: asyncDocuments.when(
        data: (documents) {
          if (documents.isEmpty) {
            return const Center(child: Text('문서가 없습니다.'));
          }

          // 필터 정보 표시
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 필터 정보 표시
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '필터: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _filterDocumentType.isEmpty
                              ? '모든 문서 유형'
                              : documents
                                  .firstWhere(
                                    (doc) =>
                                        doc.documentType == _filterDocumentType,
                                  )
                                  .documentTypeName,
                        ),
                        const Text(' / '),
                        Text(
                          _filterStatus.isEmpty
                              ? '모든 상태'
                              : _getStatusName(_filterStatus),
                        ),
                        const Spacer(),
                        Text('총 ${filteredDocuments.length}건'),
                      ],
                    ),
                    if (_filterDocumentType.isNotEmpty ||
                        _filterStatus.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterDocumentType = '';
                            _filterStatus = '';
                          });
                        },
                        child: const Text('필터 초기화'),
                      ),
                  ],
                ),
              ),

              // 문서 목록
              Expanded(
                child: ListView.builder(
                  itemCount: filteredDocuments.length,
                  itemBuilder: (context, index) {
                    final document = filteredDocuments[index];
                    return DocumentListTile(document: document);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('에러 발생: $error')),
      ),
    );
  }

  // 상태명 변환
  String _getStatusName(String status) {
    switch (status) {
      case 'submitted':
        return '제출 완료';
      case 'pending':
        return '대기 중';
      case 'missing':
        return '미제출';
      default:
        return status;
    }
  }
}

/// 문서 목록 아이템
class DocumentListTile extends ConsumerWidget {
  /// 기본 생성자
  const DocumentListTile({super.key, required this.document});

  /// 표시할 문서
  final DocumentModel document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태에 따른 색상 설정
    final Color statusColor = _getStatusColor(document.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor: _getDocumentTypeColor(document.documentType),
          child: Icon(
            _getDocumentTypeIcon(document.documentType),
            color: Colors.white,
          ),
        ),
        title: Text(
          document.documentTypeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // 상태 표시
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusName(document.status),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 4),
                Text(
                  document.submittedAt != null
                      ? '제출: ${document.submittedAt!.year}/${document.submittedAt!.month}/${document.submittedAt!.day}'
                      : '생성: ${document.createdAt.year}/${document.createdAt.month}/${document.createdAt.day}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),

            // 파일 정보 (있는 경우)
            if (document.fileName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.insert_drive_file, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      document.fileName!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // 문서 상세 화면으로 이동
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => DocumentDetailScreen(documentId: document.id),
            ),
          );
        },
      ),
    );
  }

  // 문서 유형에 따른 아이콘
  IconData _getDocumentTypeIcon(String documentType) {
    switch (documentType) {
      case 'personal_info':
        return Icons.privacy_tip;
      case 'portrait_rights':
        return Icons.face;
      case 'equipment_rental':
        return Icons.videocam;
      case 'facility_guidelines':
        return Icons.business;
      case 'satisfaction_survey':
        return Icons.thumbs_up_down;
      default:
        return Icons.description;
    }
  }

  // 문서 유형에 따른 색상
  Color _getDocumentTypeColor(String documentType) {
    switch (documentType) {
      case 'personal_info':
        return Colors.blue;
      case 'portrait_rights':
        return Colors.purple;
      case 'equipment_rental':
        return Colors.teal;
      case 'facility_guidelines':
        return Colors.indigo;
      case 'satisfaction_survey':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  // 상태에 따른 색상
  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'missing':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 상태명 변환
  String _getStatusName(String status) {
    switch (status) {
      case 'submitted':
        return '제출 완료';
      case 'pending':
        return '대기 중';
      case 'missing':
        return '미제출';
      default:
        return status;
    }
  }
}
