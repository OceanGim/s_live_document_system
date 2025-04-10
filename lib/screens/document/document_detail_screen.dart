import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/models/document_model.dart';
import 'package:s_live_document_system/providers/document_provider.dart';
import 'package:s_live_document_system/widgets/signature_canvas.dart';
import 'package:url_launcher/url_launcher.dart';

/// 문서 상세 화면
class DocumentDetailScreen extends ConsumerStatefulWidget {
  /// 기본 생성자
  const DocumentDetailScreen({super.key, required this.documentId});

  /// 문서 ID
  final String documentId;

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 문서 정보 로드
    Future.microtask(() {
      ref.read(documentProvider.notifier).fetchDocument(widget.documentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final documentState = ref.watch(documentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('문서 상세'),
        actions: [
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(documentProvider.notifier)
                  .fetchDocument(widget.documentId);
            },
          ),
        ],
      ),
      body: documentState.when(
        data: (document) {
          if (document == null) {
            return const Center(child: Text('문서를 찾을 수 없습니다.'));
          }

          return DocumentDetailView(document: document);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('문서 로드 중 오류 발생: $error', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(documentProvider.notifier)
                            .fetchDocument(widget.documentId);
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

/// 문서 상세 정보 표시 위젯
class DocumentDetailView extends ConsumerStatefulWidget {
  /// 기본 생성자
  const DocumentDetailView({super.key, required this.document});

  /// 표시할 문서
  final DocumentModel document;

  @override
  ConsumerState<DocumentDetailView> createState() => _DocumentDetailViewState();
}

class _DocumentDetailViewState extends ConsumerState<DocumentDetailView> {
  bool _isSubmitting = false;
  bool _signatureExists = false;

  @override
  void initState() {
    super.initState();
    _signatureExists = widget.document.signatureUrl != null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문서 헤더 정보
          _buildDocumentHeader(),
          const SizedBox(height: 24),

          // 문서 상태 정보
          _buildDocumentStatus(),
          const SizedBox(height: 24),

          // 문서 파일 정보 (있는 경우)
          if (widget.document.fileUrl != null) ...[
            _buildDocumentFile(),
            const SizedBox(height: 24),
          ],

          // 서명 섹션 (제출 완료되지 않은 경우)
          if (!widget.document.isSubmitted) ...[
            const Divider(),
            const SizedBox(height: 16),
            _buildSignatureSection(),
          ] else if (widget.document.signatureUrl != null) ...[
            // 서명 이미지 표시 (제출된 경우)
            _buildSubmittedSignature(),
          ],
        ],
      ),
    );
  }

  /// 문서 헤더 정보 위젯
  Widget _buildDocumentHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getDocumentTypeColor(),
                  child: Icon(_getDocumentTypeIcon(), color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.document.documentTypeName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '문서 ID: ${widget.document.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 상세 정보 테이블
            _buildInfoTable(),
          ],
        ),
      ),
    );
  }

  /// 문서 정보 테이블
  Widget _buildInfoTable() {
    return Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
      children: [
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('생성일', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '${widget.document.createdAt.year}년 ${widget.document.createdAt.month}월 ${widget.document.createdAt.day}일',
              ),
            ),
          ],
        ),
        if (widget.document.submittedAt != null)
          TableRow(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '제출일',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '${widget.document.submittedAt!.year}년 ${widget.document.submittedAt!.month}월 ${widget.document.submittedAt!.day}일',
                ),
              ),
            ],
          ),
        if (widget.document.updatedAt != null)
          TableRow(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '수정일',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '${widget.document.updatedAt!.year}년 ${widget.document.updatedAt!.month}월 ${widget.document.updatedAt!.day}일',
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// 문서 상태 정보 위젯
  Widget _buildDocumentStatus() {
    final Color statusColor = _getStatusColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getStatusName(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(_getStatusDescription())),
          ],
        ),
      ),
    );
  }

  /// 문서 파일 정보 위젯
  Widget _buildDocumentFile() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '첨부 파일',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(widget.document.fileName ?? '문서 파일'),
              subtitle: Text(widget.document.filePath ?? ''),
              trailing: const Icon(Icons.open_in_new),
              onTap: _openDocumentFile,
            ),
          ],
        ),
      ),
    );
  }

  /// 서명 섹션 위젯
  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '서명',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('아래에 서명하여 문서를 제출하세요.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),

        // 서명 캔버스
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              _signatureExists
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text('서명이 등록되었습니다'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _signatureExists = false;
                            });
                          },
                          child: const Text('다시 서명하기'),
                        ),
                      ],
                    ),
                  )
                  : SignatureCanvas(
                    onSignatureChanged: (data) {
                      // 서명 데이터 처리
                      setState(() {
                        _signatureExists = data != null;
                      });
                    },
                  ),
        ),
        const SizedBox(height: 16),

        // 제출 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitDocument,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text('문서 제출하기'),
          ),
        ),
      ],
    );
  }

  /// 제출된 서명 이미지 위젯
  Widget _buildSubmittedSignature() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '서명',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        widget.document.signatureUrl != null
                            ? Image.network(
                              widget.document.signatureUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                            : const Center(child: Text('서명 없음')),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.document.submittedAt != null
                        ? '${widget.document.submittedAt!.year}년 ${widget.document.submittedAt!.month}월 ${widget.document.submittedAt!.day}일 제출됨'
                        : '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 문서 제출 처리
  Future<void> _submitDocument() async {
    // TODO: 실제 서명 데이터 가져오기
    // 현재는 임시 구현으로 서명 없이 제출 처리

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await ref
          .read(documentProvider.notifier)
          .submitDocument(widget.document.id, widget.document.signatureUrl);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('문서가 성공적으로 제출되었습니다.')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('문서 제출 중 오류가 발생했습니다.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// 문서 파일 열기
  void _openDocumentFile() async {
    if (widget.document.fileUrl == null) return;

    final url = Uri.parse(widget.document.fileUrl!);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('파일을 열 수 없습니다.')));
      }
    }
  }

  /// 문서 유형에 따른 아이콘
  IconData _getDocumentTypeIcon() {
    switch (widget.document.documentType) {
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

  /// 문서 유형에 따른 색상
  Color _getDocumentTypeColor() {
    switch (widget.document.documentType) {
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

  /// 상태에 따른 색상
  Color _getStatusColor() {
    switch (widget.document.status) {
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

  /// 상태명 변환
  String _getStatusName() {
    switch (widget.document.status) {
      case 'submitted':
        return '제출 완료';
      case 'pending':
        return '대기 중';
      case 'missing':
        return '미제출';
      default:
        return widget.document.status;
    }
  }

  /// 상태 설명 텍스트
  String _getStatusDescription() {
    switch (widget.document.status) {
      case 'submitted':
        return '이 문서는 제출이 완료되었습니다.';
      case 'pending':
        return '이 문서는 제출 대기 중입니다. 서명 후 제출해주세요.';
      case 'missing':
        return '이 문서는 미제출 상태입니다. 작성 후 제출이 필요합니다.';
      default:
        return '상태 정보가 없습니다.';
    }
  }
}
