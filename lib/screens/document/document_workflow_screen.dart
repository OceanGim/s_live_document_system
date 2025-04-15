import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/providers/document_provider.dart';
import 'package:s_live_document_system/providers/document_workflow_provider.dart';
import 'package:s_live_document_system/screens/document/equipment_rental_form.dart';
import 'package:s_live_document_system/screens/document/facility_agreement_form.dart';
import 'package:s_live_document_system/screens/document/portrait_rights_form.dart';
import 'package:s_live_document_system/screens/document/privacy_agreement_form.dart';
import 'package:s_live_document_system/screens/document/satisfaction_survey_form.dart';
import 'package:s_live_document_system/utils/logger.dart';

/// 문서 작성 워크플로우 화면
/// 문서 작성의 순서를 관리하는 화면입니다.
class DocumentWorkflowScreen extends ConsumerStatefulWidget {
  /// 기본 생성자
  const DocumentWorkflowScreen({super.key});

  @override
  ConsumerState<DocumentWorkflowScreen> createState() =>
      _DocumentWorkflowScreenState();
}

class _DocumentWorkflowScreenState
    extends ConsumerState<DocumentWorkflowScreen> {
  // 문서 작성 단계
  static const int STEP_INTRO = 0; // 소개 화면
  static const int STEP_FACILITY = 1; // 스튜디오 시설 이용자 준수사항
  static const int STEP_PORTRAIT = 2; // 초상권 이용동의서
  static const int STEP_PRIVACY = 3; // 개인정보 수집이용 동의서
  static const int STEP_EQUIPMENT = 4; // 장비대여 신청서
  static const int STEP_SURVEY = 5; // 만족도 조사
  static const int STEP_PREVIEW = 6; // 미리보기 및 최종 확인
  static const int STEP_COMPLETE = 7; // 작성 완료

  // 현재 단계
  int _currentStep = STEP_INTRO;

  // 초상권 동의서 인원수
  int _portraitParticipantCount = 1;
  bool _portraitParticipantInputComplete = false; // 참가자 수 입력 완료 여부

  // 각 서류 완료 상태
  bool _facilityCompleted = false;
  bool _portraitCompleted = false;
  bool _privacyCompleted = false;
  bool _equipmentCompleted = false;
  bool _surveyCompleted = false;

  @override
  Widget build(BuildContext context) {
    // 현재 단계에 따른 화면 표시
    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        actions: [
          // 디버그 용도 - 모든 단계 완료 처리
          IconButton(
            icon: const Icon(Icons.check_circle),
            tooltip: '모든 단계 완료 처리 (디버그용)',
            onPressed: () {
              setState(() {
                _facilityCompleted = true;
                _portraitCompleted = true;
                _privacyCompleted = true;
                _equipmentCompleted = true;
                _surveyCompleted = true;
              });
            },
          ),
        ],
      ),
      body: _buildCurrentStepContent(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // 현재 단계에 따른 제목
  String _getStepTitle() {
    switch (_currentStep) {
      case STEP_INTRO:
        return '스튜디오 대관 서류 작성';
      case STEP_FACILITY:
        return '시설 이용자 준수사항';
      case STEP_PORTRAIT:
        return '초상권 이용동의서';
      case STEP_PRIVACY:
        return '개인정보 수집이용 동의서';
      case STEP_EQUIPMENT:
        return '장비대여 신청서';
      case STEP_SURVEY:
        return '만족도 조사';
      case STEP_PREVIEW:
        return '작성 내용 확인';
      case STEP_COMPLETE:
        return '서류 작성 완료';
      default:
        return '스튜디오 대관 서류 작성';
    }
  }

  // 현재 단계에 따른 화면 내용
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case STEP_INTRO:
        return _buildIntroStep();
      case STEP_FACILITY:
        return _buildFacilityAgreementStep();
      case STEP_PORTRAIT:
        return _buildPortraitRightsStep();
      case STEP_PRIVACY:
        return _buildPrivacyAgreementContent();
      case STEP_EQUIPMENT:
        return _buildEquipmentRentalContent();
      case STEP_SURVEY:
        return _buildSatisfactionSurveyContent();
      case STEP_PREVIEW:
        return _buildPreviewStep();
      case STEP_COMPLETE:
        return _buildCompleteStep();
      default:
        return const Center(child: Text('잘못된 단계입니다.'));
    }
  }

  // 소개 화면
  Widget _buildIntroStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 소개 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '스튜디오 대관 서류 작성',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '스튜디오를 이용하기 위해 필요한 서류를 작성합니다. '
                    '각 서류는 순서대로 작성해야 하며, 작성 완료된 서류는 건너뛸 수 있습니다.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '작성 순서:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildStepListItem(1, '스튜디오 시설 이용자 준수사항', _facilityCompleted),
                  _buildStepListItem(2, '초상권 이용동의서 (선택)', _portraitCompleted),
                  _buildStepListItem(
                    3,
                    '개인정보 수집이용 동의서 (선택)',
                    _privacyCompleted,
                  ),
                  _buildStepListItem(4, '장비대여 신청서', _equipmentCompleted),
                  _buildStepListItem(5, '만족도 조사', _surveyCompleted),
                  const SizedBox(height: 16),
                  Text(
                    '선택 서류를 제외한 모든 서류는 필수로 작성해야 합니다.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // 시작 버튼
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = STEP_FACILITY;
              });
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('서류 작성 시작하기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 초상권 이용동의서 단계
  Widget _buildPortraitRightsStep() {
    // 먼저 참가자 수 입력 화면을 보여주고, 입력 후 동의서 화면으로 이동
    if (!_portraitParticipantInputComplete) {
      return _buildParticipantCountInput();
    }

    // 워크플로우 파라미터 생성
    final params = DocumentWorkflowProviderParams(
      documentType: 'portrait_rights',
    );

    // DocumentWorkflowNotifier에 폼 데이터 설정을 지연 실행으로 처리
    Future.microtask(() {
      if (mounted) {
        ref.read(documentWorkflowProvider.notifier).setFormData({
          'documentType': 'portrait_rights',
          'participantCount': _portraitParticipantCount,
        });
      }
    });

    return PortraitRightsForm(
      onCompleted: () {
        setState(() {
          _portraitCompleted = true;
          _currentStep = STEP_PRIVACY; // 다음 단계로 이동
        });
      },
      providerParams: params,
      participantCount: _portraitParticipantCount,
    );
  }

  // 참가자 수 입력 화면
  Widget _buildParticipantCountInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              '촬영에 참여하는 인원 수를 입력해주세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '참가자 수에 따라 각 참가자의 서명을 받아야 합니다.\n참가자 수를 정확히 입력해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            // 참가자 수 선택 UI
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed:
                      _portraitParticipantCount > 1
                          ? () {
                            setState(() {
                              _portraitParticipantCount--;
                            });
                          }
                          : null,
                  icon: const Icon(Icons.remove_circle),
                  iconSize: 36,
                  color: Colors.blue,
                ),
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _portraitParticipantCount.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      _portraitParticipantCount < 10
                          ? () {
                            setState(() {
                              _portraitParticipantCount++;
                            });
                          }
                          : null,
                  icon: const Icon(Icons.add_circle),
                  iconSize: 36,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 48),
            // 확인 버튼
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _portraitParticipantInputComplete = true;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('확인', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // 작성 완료 화면
  Widget _buildCompleteStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 120),
          const SizedBox(height: 24),
          Text(
            '모든 서류 작성이 완료되었습니다!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '작성한 내용이 저장되었습니다.\n이용해 주셔서 감사합니다.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // 안전하게 홈화면으로 전환
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            icon: const Icon(Icons.home),
            label: const Text('홈으로 돌아가기'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              // 로그아웃 처리
              try {
                final authNotifier = ref.read(authProvider.notifier);
                await authNotifier.signOut();

                // 안전하게 홈화면으로 전환
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              } catch (e) {
                Logger.error('로그아웃 오류', error: e, tag: 'DocumentWorkflow');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('로그아웃 중 오류가 발생했습니다.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃하기'),
          ),
        ],
      ),
    );
  }

  // 시설 이용 준수사항 동의서 단계
  Widget _buildFacilityAgreementStep() {
    // 워크플로우 파라미터 생성
    final params = DocumentWorkflowProviderParams(
      documentType: 'facility_guidelines',
    );

    // DocumentWorkflowNotifier에 폼 데이터 설정은 initState 또는 버튼 이벤트에서 수행해야 함
    // build 메서드에서 호출하면 안됨
    // 대신 지연 실행으로 처리
    Future.microtask(() {
      if (mounted) {
        ref.read(documentWorkflowProvider.notifier).setFormData({
          'documentType': 'facility_guidelines',
        });
      }
    });

    return FacilityAgreementForm(
      onCompleted: () {
        setState(() {
          _facilityCompleted = true;
          _currentStep = STEP_PORTRAIT; // 다음 단계로 이동
        });
      },
      providerParams: params,
    );
  }

  // 임시 내용 표시 위젯
  Widget _buildPlaceholderContent(String message) {
    // 현재 단계에 따라 콘텐츠 렌더링
    if (_currentStep == STEP_PRIVACY) {
      return _buildPrivacyAgreementContent();
    } else if (_currentStep == STEP_EQUIPMENT) {
      return _buildEquipmentRentalContent();
    } else if (_currentStep == STEP_SURVEY) {
      return _buildSatisfactionSurveyContent();
    }

    // 현재 단계에 맞게 건너뛰기 버튼을 포함시킬지 결정
    final bool showSkipButton =
        _currentStep == STEP_PRIVACY || _currentStep == STEP_EQUIPMENT;
    final String skipButtonLabel =
        _currentStep == STEP_PRIVACY
            ? '이 서류는 선택사항입니다. 건너뛰기'
            : '장비대여가 필요 없습니다. 건너뛰기';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            // 동의 및 제출 버튼
            ElevatedButton.icon(
              onPressed: () {
                // 사용자에게 동의 확인받기
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('동의 및 제출 확인'),
                        content: const Text(
                          '입력하신 내용에 동의하며 제출하시겠습니까?\n제출 후에는 수정이 제한될 수 있습니다.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();

                              // 작성 완료 처리 후 자동으로 다음 단계로 이동
                              setState(() {
                                // 현재 단계 완료 처리
                                _completeCurrentStep();

                                // 다음 단계로 자동 이동
                                if (_currentStep < STEP_COMPLETE) {
                                  _currentStep++;
                                }

                                // 모든 단계가 완료되었다면 완료 화면으로 이동
                                if (_facilityCompleted &&
                                    _equipmentCompleted &&
                                    _surveyCompleted &&
                                    _currentStep == STEP_SURVEY) {
                                  _currentStep = STEP_COMPLETE;
                                }
                              });
                            },
                            child: const Text('동의 및 제출'),
                          ),
                        ],
                      ),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('동의 및 제출'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
              ),
            ),

            // 건너뛰기 버튼 (필요한 경우만 표시)
            if (showSkipButton) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    // 건너뛸 경우 완료 처리
                    if (_currentStep == STEP_PRIVACY) {
                      _privacyCompleted = true;
                      _currentStep = STEP_EQUIPMENT;
                    } else if (_currentStep == STEP_EQUIPMENT) {
                      _equipmentCompleted = true;
                      _currentStep = STEP_SURVEY;
                    }
                  });
                },
                child: Text(skipButtonLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 개인정보 수집이용 동의서 화면
  Widget _buildPrivacyAgreementContent() {
    // 워크플로우 파라미터 생성
    final params = DocumentWorkflowProviderParams(
      documentType: 'personal_info',
    );

    // DocumentWorkflowNotifier에 폼 데이터 설정을 지연 실행으로 처리
    Future.microtask(() {
      if (mounted) {
        ref.read(documentWorkflowProvider.notifier).setFormData({
          'documentType': 'personal_info',
        });
      }
    });

    return PrivacyAgreementForm(
      onCompleted: () {
        setState(() {
          _privacyCompleted = true;
          _currentStep = STEP_EQUIPMENT; // 다음 단계로 이동
        });
      },
      providerParams: params,
    );
  }

  // 만족도 조사 화면
  Widget _buildSatisfactionSurveyContent() {
    // 워크플로우 파라미터 생성
    final params = DocumentWorkflowProviderParams(
      documentType: 'satisfaction_survey',
    );

    // DocumentWorkflowNotifier에 폼 데이터 설정을 지연 실행으로 처리
    Future.microtask(() {
      if (mounted) {
        ref.read(documentWorkflowProvider.notifier).setFormData({
          'documentType': 'satisfaction_survey',
        });
      }
    });

    return SatisfactionSurveyForm(
      onCompleted: () {
        setState(() {
          _surveyCompleted = true;
          // 모든 필수 단계가 완료되었다면 미리보기 단계로 이동
          if (_facilityCompleted && _equipmentCompleted) {
            _currentStep = STEP_PREVIEW;
          } else {
            // 아직 완료되지 않은 필수 단계가 있으면 다음 단계로 이동
            _currentStep = STEP_PREVIEW;
          }
        });
      },
      providerParams: params,
    );
  }

  // 장비 대여 신청서 화면
  Widget _buildEquipmentRentalContent() {
    // 건너뛰기 버튼을 포함한 화면 구성
    return Column(
      children: [
        Expanded(child: _buildEquipmentRentalForm()),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: OutlinedButton.icon(
            onPressed: () {
              // 건너뛰기 전 확인 대화상자 표시
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('장비 대여 신청서 건너뛰기'),
                      content: const Text(
                        '장비 대여가 필요하지 않으시면 건너뛸 수 있습니다. 계속하시겠습니까?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _equipmentCompleted = true;
                              _currentStep = STEP_SURVEY; // 다음 단계로 이동
                            });
                          },
                          child: const Text('건너뛰기'),
                        ),
                      ],
                    ),
              );
            },
            icon: const Icon(Icons.skip_next),
            label: const Text('장비 대여가 필요하지 않습니다. 건너뛰기'),
          ),
        ),
      ],
    );
  }

  // 장비 대여 폼 위젯
  Widget _buildEquipmentRentalForm() {
    // 워크플로우 파라미터 생성
    final params = DocumentWorkflowProviderParams(
      documentType: 'equipment_rental',
    );

    // DocumentWorkflowNotifier에 폼 데이터 설정을 지연 실행으로 처리
    Future.microtask(() {
      if (mounted) {
        ref.read(documentWorkflowProvider.notifier).setFormData({
          'documentType': 'equipment_rental',
        });
      }
    });

    return EquipmentRentalForm(
      onCompleted: () {
        setState(() {
          _equipmentCompleted = true;
          _currentStep = STEP_SURVEY; // 다음 단계로 이동
        });
      },
      providerParams: params,
    );
  }

  // 미리보기 및 최종 확인 단계
  Widget _buildPreviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 제목
          const Text(
            '작성하신 내용을 확인해주세요',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // 작성한 서류 목록 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '작성 완료한 서류',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 필수 서류
                  _buildCompletedDocumentItem(
                    '시설 이용자 준수사항',
                    true,
                    _facilityCompleted,
                  ),
                  _buildCompletedDocumentItem(
                    '장비대여 신청서',
                    true,
                    _equipmentCompleted,
                  ),
                  _buildCompletedDocumentItem('만족도 조사', true, _surveyCompleted),

                  // 선택 서류
                  _buildCompletedDocumentItem(
                    '초상권 이용동의서',
                    false,
                    _portraitCompleted,
                  ),
                  _buildCompletedDocumentItem(
                    '개인정보 수집이용 동의서',
                    false,
                    _privacyCompleted,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 위의 정보가 맞는지 확인하는 텍스트
          const Text(
            '위 내용이 맞으면 아래 버튼을 눌러 제출을 완료해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 32),

          // 제출 완료 버튼
          ElevatedButton.icon(
            onPressed: () async {
              // 로딩 표시
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) =>
                        const Center(child: CircularProgressIndicator()),
              );

              // 모든 문서를 DB에 저장
              final saveResult = await _saveAllDocumentsToDb();

              // 로딩 다이얼로그 닫기
              Navigator.of(context, rootNavigator: true).pop();

              if (saveResult) {
                // 저장 성공 시 완료 화면으로 이동
                setState(() {
                  _currentStep = STEP_COMPLETE;
                });

                // 성공 메시지 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('모든 서류가 성공적으로 제출되었습니다.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } else {
                // 저장 실패 시 오류 메시지 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('서류 저장 중 오류가 발생했습니다. 다시 시도해주세요.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('모든 서류 제출 완료'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
          ),
        ],
      ),
    );
  }

  // 완료된 문서 항목
  Widget _buildCompletedDocumentItem(
    String title,
    bool isRequired,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // 상태 아이콘
          isCompleted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.cancel, color: Colors.red),
          const SizedBox(width: 12),

          // 문서 제목
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          // 필수 여부 표시
          if (isRequired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '필수',
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 단계 리스트 아이템
  Widget _buildStepListItem(int step, String title, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  completed
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child:
                  completed
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                        step.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                decoration: completed ? TextDecoration.lineThrough : null,
                color: completed ? Colors.grey : null,
              ),
            ),
          ),
          if (completed)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  // 참가자 카드 (이름과 서명만 포함)
  Widget _buildParticipantCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '참가자 ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 삭제 버튼 (마지막 참가자만 삭제 가능)
                if (_portraitParticipantCount > 1 &&
                    index == _portraitParticipantCount - 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _portraitParticipantCount--;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // 이름만 입력 필드
            TextFormField(
              decoration: const InputDecoration(
                labelText: '이름',
                hintText: '참가자 이름을 입력하세요',
              ),
            ),
            const SizedBox(height: 16),
            // 서명 영역
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('여기에 서명')),
            ),
            const SizedBox(height: 16),
            // 서명 완료 버튼
            ElevatedButton.icon(
              onPressed: () {
                // 개별 참가자 동의서 완료 처리 (실제 로직 필요)
                // 모든 참가자가 완료되면 전체 완료 처리
                if (index == _portraitParticipantCount - 1) {
                  setState(() {
                    _portraitCompleted = true;
                    // 작성 완료 후 다음 단계로 자동 이동
                    _currentStep = STEP_PRIVACY;
                  });
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('서명 완료'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DB에 모든 서류 저장
  Future<bool> _saveAllDocumentsToDb() async {
    // 개발 모드에서는 DB 저장 없이 성공으로 처리
    // 실제 DB 테이블이 준비되지 않은 상태에서 테스트하기 위함
    try {
      // 로딩 표시 (시각적 피드백)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 개발 테스트 환경을 위해 저장 시뮬레이션 (2초 지연)
      await Future.delayed(const Duration(seconds: 2));

      // 로그 기록
      Logger.info('개발 테스트 모드: 문서 저장 시뮬레이션 완료', tag: 'DocumentWorkflow');

      // 로딩 다이얼로그 닫기
      Navigator.of(context, rootNavigator: true).pop();

      // 항상 성공 반환
      return true;
    } catch (e) {
      Logger.error('개발 테스트 중 오류', error: e, tag: 'DocumentWorkflow');

      // 로딩 다이얼로그 닫기 시도
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}

      return false;
    }
  }

  // 하단 네비게이션 버튼
  Widget _buildBottomNavigation() {
    // 첫 단계나 완료 단계에서는 표시하지 않음
    if (_currentStep == STEP_INTRO || _currentStep == STEP_COMPLETE) {
      return const SizedBox.shrink();
    }

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 이전 단계 버튼
            TextButton.icon(
              onPressed: _currentStep > STEP_INTRO ? _goToPreviousStep : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('이전'),
            ),
            // 다음 단계 버튼
            TextButton.icon(
              onPressed: _canMoveToNextStep() ? _goToNextStep : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }

  // 현재 단계 완료 처리
  void _completeCurrentStep() {
    setState(() {
      switch (_currentStep) {
        case STEP_FACILITY:
          _facilityCompleted = true;
          break;
        case STEP_PORTRAIT:
          _portraitCompleted = true;
          break;
        case STEP_PRIVACY:
          _privacyCompleted = true;
          break;
        case STEP_EQUIPMENT:
          _equipmentCompleted = true;
          break;
        case STEP_SURVEY:
          _surveyCompleted = true;
          break;
      }
    });
  }

  // 다음 단계로 이동 가능한지 확인
  bool _canMoveToNextStep() {
    switch (_currentStep) {
      case STEP_FACILITY:
        return _facilityCompleted;
      case STEP_PORTRAIT:
        // 초상권 동의서는 선택사항이므로 건너뛸 수 있음
        return true;
      case STEP_PRIVACY:
        // 개인정보 수집 동의서도 선택사항
        return true;
      case STEP_EQUIPMENT:
        return _equipmentCompleted;
      case STEP_SURVEY:
        return _surveyCompleted;
      default:
        return false;
    }
  }

  // 이전 단계로 이동
  void _goToPreviousStep() {
    if (_currentStep > STEP_INTRO) {
      setState(() {
        _currentStep--;
      });
    }
  }

  // 다음 단계로 이동
  void _goToNextStep() {
    // 다음 단계 계산
    int nextStep = _currentStep;

    // 현재 단계가 초상권 동의서이고 완료되지 않았으면 건너뛰기
    if (_currentStep == STEP_PORTRAIT && !_portraitCompleted) {
      // 사용자에게 건너뛸지 확인
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('초상권 동의서 건너뛰기'),
              content: const Text(
                '초상권 동의서 작성을 완료하지 않았습니다. 이 서류는 선택사항이므로 건너뛸 수 있습니다. 계속하시겠습니까?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentStep = STEP_PRIVACY;
                    });
                  },
                  child: const Text('건너뛰기'),
                ),
              ],
            ),
      );
      return;
    }

    // 현재 단계가 개인정보 동의서이고 완료되지 않았으면 건너뛰기
    if (_currentStep == STEP_PRIVACY && !_privacyCompleted) {
      // 사용자에게 건너뛸지 확인
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('개인정보 동의서 건너뛰기'),
              content: const Text(
                '개인정보 수집이용 동의서 작성을 완료하지 않았습니다. 이 서류는 선택사항이므로 건너뛸 수 있습니다. 계속하시겠습니까?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentStep = STEP_EQUIPMENT;
                    });
                  },
                  child: const Text('건너뛰기'),
                ),
              ],
            ),
      );
      return;
    }

    // 다음 단계로 이동
    if (_currentStep < STEP_COMPLETE) {
      setState(() {
        _currentStep++;
      });
    }

    // 모든 필수 서류 작성이 완료되면 미리보기 단계로 이동
    if (_facilityCompleted &&
        _equipmentCompleted &&
        _surveyCompleted &&
        _currentStep == STEP_SURVEY) {
      setState(() {
        _currentStep = STEP_PREVIEW;
      });
    }
  }
}
