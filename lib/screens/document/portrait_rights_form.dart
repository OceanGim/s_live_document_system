import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/constants/app_colors.dart';
import 'package:s_live_document_system/providers/document_workflow_provider.dart';
import 'package:s_live_document_system/services/signature_service.dart';
import 'package:s_live_document_system/widgets/custom_button.dart';
import 'package:s_live_document_system/widgets/signature_canvas.dart';
import 'package:s_live_document_system/utils/logger.dart';

/// 초상권 이용 동의서 양식
class PortraitRightsForm extends ConsumerStatefulWidget {
  /// 기본 생성자
  const PortraitRightsForm({
    super.key,
    required this.onCompleted,
    required this.providerParams,
    this.participantCount = 1,
  });

  /// 양식 완료 콜백
  final VoidCallback onCompleted;

  /// 문서 워크플로우 제공자 매개변수
  final DocumentWorkflowProviderParams providerParams;

  /// 참가자 수
  final int participantCount;

  @override
  ConsumerState<PortraitRightsForm> createState() => _PortraitRightsFormState();
}

class _PortraitRightsFormState extends ConsumerState<PortraitRightsForm> {
  final _formKey = GlobalKey<FormState>();
  final List<ParticipantData> _participants = [];
  bool _agreedToTerms = false;
  int _currentParticipantIndex = 0;
  bool _isLoading = false;
  bool _hasSavedSignature = false;
  Uint8List? _savedSignatureData;
  final SignatureService _signatureService = SignatureService();

  @override
  void initState() {
    super.initState();

    // 참가자 데이터 초기화
    for (var i = 0; i < widget.participantCount; i++) {
      _participants.add(
        ParticipantData(
          nameController: TextEditingController(),
          phoneController: TextEditingController(),
          emailController: TextEditingController(),
          signatureData: null,
          hasSignature: false,
        ),
      );
    }

    // 기존 데이터가 있으면 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedSignature();
      _loadExistingData();
    });
  }

  // 저장된 서명 불러오기
  Future<void> _loadSavedSignature() async {
    try {
      setState(() => _isLoading = true);

      // 테스트 모드에서는 메모리에 서명 데이터가 있으면 사용
      if (_savedSignatureData != null) {
        setState(() {
          _hasSavedSignature = true;
          _isLoading = false;
        });
        return;
      }

      // 실제 DB에서 서명 불러오기 시도 (개발 모드에선 작동 안 함)
      final signature = await _signatureService.getCurrentUserSignature();
      if (signature != null) {
        setState(() {
          _savedSignatureData = signature;
          _hasSavedSignature = true;
        });

        Logger.info('저장된 서명 불러오기 성공', tag: 'PortraitRightsForm');
      }
    } catch (e) {
      Logger.error('서명 불러오기 오류', error: e, tag: 'PortraitRightsForm');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 기존 문서 데이터 불러오기
  void _loadExistingData() {
    final workflowState = ref.read(documentWorkflowProvider);
    final Map<String, dynamic> formData = workflowState.formData ?? {};

    if (formData.isNotEmpty && formData['participants'] != null) {
      final participants = formData['participants'] as List;

      // 저장된 참가자 수만큼 데이터 로드
      for (
        var i = 0;
        i < participants.length && i < _participants.length;
        i++
      ) {
        final participant = participants[i] as Map<String, dynamic>;
        _participants[i].nameController.text = participant['name'] ?? '';
        _participants[i].phoneController.text = participant['phone'] ?? '';
        _participants[i].emailController.text = participant['email'] ?? '';
        _participants[i].hasSignature = participant['has_signature'] ?? false;
      }

      if (formData['agreed_to_terms'] == true) {
        setState(() {
          _agreedToTerms = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // 컨트롤러 정리
    for (var participant in _participants) {
      participant.nameController.dispose();
      participant.phoneController.dispose();
      participant.emailController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 워크플로우 상태 감시
    final workflowState = ref.watch(documentWorkflowProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24.0),
            _buildAgreementText(),
            const SizedBox(height: 24.0),
            _buildParticipantNavigator(),
            const SizedBox(height: 16.0),
            _buildCurrentParticipantForm(),
            const SizedBox(height: 24.0),
            _buildAgreementCheckbox(),
            const SizedBox(height: 24.0),
            _buildActionButtons(workflowState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '초상권 이용 동의서',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Text(
          '촬영 참가자의 초상권 이용에 대한 동의서입니다. 참가자 ${_participants.length}명에 대한 정보를 입력해주세요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildAgreementText() {
    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. 촬영 목적',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text('스튜디오 대관을 통한 영상/사진 콘텐츠 제작'),
            const SizedBox(height: 16.0),
            const Text(
              '2. 초상권 이용 범위',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text(
              '촬영된 영상 및 사진은 다음 목적으로 활용될 수 있습니다:\n'
              '- 스튜디오 홍보 목적\n'
              '- 상업적 목적의 콘텐츠 제작\n'
              '- 소셜 미디어 및 웹사이트 게시\n'
              '- 포트폴리오 및 작품 전시',
            ),
            const SizedBox(height: 16.0),
            const Text(
              '3. 이용 기간',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text('동의일로부터 5년간'),
            const SizedBox(height: 16.0),
            const Text(
              '4. 동의 철회 방법',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text(
              '동의 철회는 언제든지 가능하며, 관리자에게 문의하여 진행할 수 있습니다. '
              '단, 이미 제작 완료된 콘텐츠에 대해서는 철회가 제한될 수 있습니다.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantNavigator() {
    return Row(
      children: [
        Text(
          '참가자 정보',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        // 참가자 선택 UI
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed:
                  _currentParticipantIndex > 0
                      ? () {
                        setState(() {
                          _currentParticipantIndex--;
                        });
                      }
                      : null,
            ),
            Text(
              '${_currentParticipantIndex + 1} / ${_participants.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
              onPressed:
                  _currentParticipantIndex < _participants.length - 1
                      ? () {
                        setState(() {
                          _currentParticipantIndex++;
                        });
                      }
                      : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentParticipantForm() {
    final participant = _participants[_currentParticipantIndex];

    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '참가자 ${_currentParticipantIndex + 1}',
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: participant.nameController,
              decoration: const InputDecoration(
                labelText: '이름 *',
                hintText: '참가자 이름을 입력하세요',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이름을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 24.0),
            Text(
              '서명',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            // 참가자1만 저장된 서명 사용 버튼 표시
            if (_hasSavedSignature && _currentParticipantIndex == 0)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.content_copy, size: 16),
                  label: const Text('저장된 서명 사용'),
                  onPressed: () {
                    setState(() {
                      participant.signatureData = _savedSignatureData;
                      participant.hasSignature = true;
                    });
                  },
                ),
              ),
            const SizedBox(height: 8.0),
            const Text(
              '아래 영역에 서명하여 초상권 이용에 동의함을 확인합니다.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16.0),
            SignatureCanvas(
              key: ValueKey('signature_${_currentParticipantIndex}'),
              initialSignature: participant.signatureData,
              onSignatureChanged: (data) {
                setState(() {
                  participant.signatureData = data;
                  participant.hasSignature = data != null;

                  // 현재 참가자가 첫 번째라면 서명 데이터 저장 (참가자 1의 서명만 저장)
                  if (data != null && _currentParticipantIndex == 0) {
                    _savedSignatureData = data;
                    _hasSavedSignature = true;
                  }
                });
              },
              height: 200.0,
              borderColor: AppColors.primary.withOpacity(0.5),
              borderRadius: 12.0,
            ),
            const SizedBox(height: 8.0),
            Text(
              '참고: 각 참가자별로 별도의 PDF 파일이 생성됩니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementCheckbox() {
    // 현재 참가자에 대한 동의 체크박스
    final participant = _participants[_currentParticipantIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: participant.agreedToTerms,
              onChanged: (value) {
                setState(() {
                  participant.agreedToTerms = value ?? false;
                  // 모든 참가자가 동의했는지 확인
                  _updateGlobalAgreement();
                });
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    participant.agreedToTerms = !participant.agreedToTerms;
                    _updateGlobalAgreement();
                  });
                },
                child: Text(
                  '참가자 ${_currentParticipantIndex + 1}는(은) 위와 같이 초상권 이용에 동의합니다.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),

        // 참가자 네비게이션 버튼 (이전, 다음)
        if (_participants.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      _currentParticipantIndex > 0
                          ? () {
                            setState(() {
                              _currentParticipantIndex--;
                            });
                          }
                          : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('이전 참가자'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton.icon(
                  onPressed:
                      _currentParticipantIndex < _participants.length - 1
                          ? () {
                            setState(() {
                              _currentParticipantIndex++;
                            });
                          }
                          : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('다음 참가자'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 전체 동의 상태 업데이트
  void _updateGlobalAgreement() {
    bool allAgreed = true;
    for (var participant in _participants) {
      if (!participant.agreedToTerms) {
        allAgreed = false;
        break;
      }
    }
    _agreedToTerms = allAgreed;
  }

  Widget _buildActionButtons(DocumentWorkflowState workflowState) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: '작성 취소',
            onPressed: () {
              // 사용자에게 확인
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('작성 취소'),
                      content: const Text('입력한 내용이 저장되지 않습니다. 취소하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('아니오'),
                        ),
                        TextButton(
                          onPressed: () {
                            // 메인 화면으로 돌아가기
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          child: const Text('예'),
                        ),
                      ],
                    ),
              );
            },
            backgroundColor: Colors.grey.shade200,
            textColor: Colors.black87,
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: CustomButton(
            text: '동의 및 제출',
            onPressed: _validateAndSubmit,
            isLoading:
                workflowState.status == DocumentWorkflowStatus.loading ||
                _isLoading,
          ),
        ),
      ],
    );
  }

  bool _validateParticipants() {
    bool allValid = true;

    // 각 참가자 데이터 유효성 검사
    for (int i = 0; i < _participants.length; i++) {
      final participant = _participants[i];

      // 이름은 필수
      if (participant.nameController.text.isEmpty) {
        // 현재 표시중인 참가자가 아니면 해당 참가자로 이동
        if (i != _currentParticipantIndex) {
          setState(() {
            _currentParticipantIndex = i;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('참가자 ${i + 1}의 이름을 입력해주세요.'),
            backgroundColor: Colors.red,
          ),
        );

        allValid = false;
        break;
      }

      // 서명 여부 확인
      if (!participant.hasSignature) {
        // 현재 표시중인 참가자가 아니면 해당 참가자로 이동
        if (i != _currentParticipantIndex) {
          setState(() {
            _currentParticipantIndex = i;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('참가자 ${i + 1}의 서명을 완료해주세요.'),
            backgroundColor: Colors.red,
          ),
        );

        allValid = false;
        break;
      }
    }

    return allValid;
  }

  void _validateAndSubmit() {
    // 폼 검증
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필수 정보를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 참가자 정보 유효성 검사
    if (!_validateParticipants()) {
      return;
    }

    // 동의 확인
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('초상권 이용에 동의해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 데이터 제출
    _submitForm();
  }

  void _submitForm() {
    // 워크플로우 프로바이더에 데이터 업데이트
    final notifier = ref.read(documentWorkflowProvider.notifier);

    // 참가자 데이터 수집
    final List<Map<String, dynamic>> participantsData = [];
    for (var participant in _participants) {
      participantsData.add({
        'name': participant.nameController.text,
        'phone': participant.phoneController.text,
        'email': participant.emailController.text,
        'has_signature': participant.hasSignature,
        'signature_date': DateTime.now().toIso8601String(),
      });
    }

    // 데이터 수집
    final formData = {
      'participants': participantsData,
      'agreed_to_terms': _agreedToTerms,
      'signature_date': DateTime.now().toIso8601String(),
      'participant_count': _participants.length,
    };

    // 폼 데이터 저장
    notifier.setFormData(formData);

    // 문서 워크플로우 상태 업데이트
    notifier.setWorkflowStatus(DocumentWorkflowStatus.loading);

    // 문서 저장 로직 시뮬레이션
    Future.delayed(const Duration(seconds: 1), () {
      // 완료 상태로 변경
      notifier.setWorkflowStatus(DocumentWorkflowStatus.completed);

      // 문서 완료 상태 설정
      notifier.setDocumentCompleted('초상권이용동의서', true);

      // 완료 콜백 호출
      widget.onCompleted();
    });
  }
}

/// 참가자 데이터 클래스
class ParticipantData {
  ParticipantData({
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    this.signatureData,
    this.hasSignature = false,
    this.agreedToTerms = false,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  Uint8List? signatureData;
  bool hasSignature;
  bool agreedToTerms; // 개별 참가자의 동의 여부
}
