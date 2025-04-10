import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/models/document_model.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/providers/document_provider.dart';
import 'package:s_live_document_system/providers/user_provider.dart';
import 'package:s_live_document_system/screens/document/document_detail_screen.dart';
import 'package:s_live_document_system/widgets/custom_button.dart';

/// 스튜디오 대관 문서 작성 화면
class DocumentCreationScreen extends ConsumerStatefulWidget {
  /// 기본 생성자
  const DocumentCreationScreen({super.key});

  @override
  ConsumerState<DocumentCreationScreen> createState() =>
      _DocumentCreationScreenState();
}

class _DocumentCreationScreenState
    extends ConsumerState<DocumentCreationScreen> {
  bool _isLoading = false;

  // 사용 가능한 문서 타입 정의
  final List<Map<String, dynamic>> _documentTypes = [
    {
      'id': 'personal_info',
      'name': '개인정보 수집이용 동의서',
      'icon': Icons.privacy_tip,
      'color': Colors.blue,
      'description': '스튜디오 대관을 위한 개인정보 수집 및 이용에 대한 동의서입니다.',
    },
    {
      'id': 'portrait_rights',
      'name': '초상권 이용동의서',
      'icon': Icons.face,
      'color': Colors.purple,
      'description': '촬영 및 촬영물 사용에 관한 초상권 이용 동의서입니다.',
    },
    {
      'id': 'facility_guidelines',
      'name': '스튜디오 시설 이용자 준수사항',
      'icon': Icons.business,
      'color': Colors.indigo,
      'description': '스튜디오 시설 이용 시 준수해야 할 사항들에 대한 안내와 동의서입니다.',
    },
    {
      'id': 'equipment_rental',
      'name': '장비 대여 신청서',
      'icon': Icons.videocam,
      'color': Colors.teal,
      'description': '스튜디오 내 장비 대여를 위한 신청서입니다.',
    },
    {
      'id': 'satisfaction_survey',
      'name': '만족도 조사',
      'icon': Icons.thumbs_up_down,
      'color': Colors.amber,
      'description': '스튜디오 사용 후 만족도 조사 설문지입니다.',
    },
  ];

  /// 문서 생성 처리
  Future<void> _createDocument(String documentType) async {
    final authState = ref.read(authProvider);
    final userId = authState.userId;

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 선택한 문서 유형에 맞는 이름 찾기
      final documentTypeName =
          _documentTypes.firstWhere(
                (element) => element['id'] == documentType,
              )['name']
              as String;

      // 문서 생성 프로바이더 호출
      final createdDocument = await ref
          .read(documentProvider.notifier)
          .createDocument(
            userId: userId,
            documentType: documentType,
            status: 'pending',
            metadata: {'name': documentTypeName}, // 문서 유형 이름 메타데이터로 저장
          );

      if (!mounted) return;

      if (createdDocument != null) {
        // 생성된 문서의 상세 화면으로 이동
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) =>
                    DocumentDetailScreen(documentId: createdDocument.id),
          ),
        );
      } else {
        // 문서 생성 실패 시 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('문서 생성에 실패했습니다. 데이터베이스 테이블이 있는지 확인하세요.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('문서 생성 실패: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('대관 서류 작성')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더 섹션
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '안녕하세요, ${userInfo?.displayName ?? '사용자'}님',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '스튜디오 대관을 위해 필요한 서류를 작성해주세요. 작성이 필요한 서류를 선택하시면 상세 작성 화면으로 이동합니다.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '필수 제출 서류',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 문서 타입 목록
                    ...(_documentTypes
                        .take(3)
                        .map((docType) => _buildDocumentCard(docType))),

                    const SizedBox(height: 24),
                    const Text(
                      '추가 서류 (필요시)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 추가 문서 타입 목록
                    ...(_documentTypes
                        .skip(3)
                        .map((docType) => _buildDocumentCard(docType))),
                  ],
                ),
              ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> docType) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _createDocument(docType['id']),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: docType['color'],
                    child: Icon(docType['icon'], color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          docType['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          docType['description'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
