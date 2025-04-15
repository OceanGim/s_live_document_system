import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/constants/app_colors.dart';
import 'package:s_live_document_system/providers/document_workflow_provider.dart';
import 'package:s_live_document_system/services/signature_service.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:s_live_document_system/widgets/custom_button.dart';
import 'package:s_live_document_system/widgets/signature_canvas.dart';

/// 개인정보 수집이용 동의서 양식
class PrivacyAgreementForm extends ConsumerStatefulWidget {
  /// 기본 생성자
  const PrivacyAgreementForm({
    super.key,
    required this.onCompleted,
    required this.providerParams,
  });

  /// 양식 완료 콜백
  final VoidCallback onCompleted;

  /// 문서 워크플로우 제공자 매개변수
  final DocumentWorkflowProviderParams providerParams;

  @override
  ConsumerState<PrivacyAgreementForm> createState() =>
      _PrivacyAgreementFormState();
}

class _PrivacyAgreementFormState extends ConsumerState<PrivacyAgreementForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  Uint8List? _signatureData;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _hasSavedSignature = false;
  Uint8List? _savedSignatureData;
  final SignatureService _signatureService = SignatureService();

  @override
  void initState() {
    super.initState();

    // 기존 데이터가 있으면 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workflowState = ref.read(documentWorkflowProvider);
      final Map<String, dynamic> formData = workflowState.formData ?? {};

      if (formData.isNotEmpty) {
        _nameController.text = formData['name'] ?? '';
        _addressController.text = formData['address'] ?? '';

        if (formData['agreed_to_terms'] == true) {
          setState(() {
            _agreedToTerms = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
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
            _buildPersonalInfoForm(),
            const SizedBox(height: 24.0),
            _buildAgreementCheckbox(),
            const SizedBox(height: 24.0),
            _buildSignatureSection(),
            const SizedBox(height: 32.0),
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
          '개인정보 수집이용 동의서',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Text(
          '귀하의 개인정보는 다음과 같은 목적과 용도로만 활용됩니다.',
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
              '1. 수집항목',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text('이름, 연락처, 이메일, 주소, 서명'),
            const SizedBox(height: 16.0),
            const Text(
              '2. 수집목적',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text('스튜디오 대관 신청 및 관리, 대관 서비스 제공, 안전관리, 사고발생시 대응'),
            const SizedBox(height: 16.0),
            const Text(
              '3. 보유기간',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text('수집일로부터 1년간 보관 후 파기'),
            const SizedBox(height: 16.0),
            const Text(
              '4. 동의를 거부할 권리 및 동의 거부에 따른 제한사항',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text(
              '귀하는 개인정보 수집·이용에 대한 동의를 거부할 권리가 있습니다. 다만, 동의를 거부할 경우 스튜디오 대관 서비스 이용이 제한될 수 있습니다.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이름 입력',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '이름 *',
            hintText: '이름을 입력하세요',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '이름을 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAgreementCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) {
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _agreedToTerms = !_agreedToTerms;
              });
            },
            child: const Text(
              '본인은 위와 같이 개인정보 수집·이용에 동의합니다.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '서명',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.content_copy, size: 16),
              label: const Text('저장된 서명 불러오기'),
              onPressed: () async {
                try {
                  setState(() => _isLoading = true);
                  final signature =
                      await _signatureService.getCurrentUserSignature();
                  if (signature != null) {
                    setState(() {
                      _signatureData = signature;
                      _savedSignatureData = signature;
                      _hasSavedSignature = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('저장된 서명을 불러왔습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('저장된 서명이 없습니다.')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('서명 불러오기 오류: ${e.toString()}')),
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        const Text(
          '아래 영역에 서명하여 개인정보 수집이용에 동의함을 확인합니다.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16.0),
        SignatureCanvas(
          initialSignature: _signatureData,
          onSignatureChanged: (data) {
            setState(() {
              _signatureData = data;
            });
          },
          height: 200.0,
          borderColor: AppColors.primary.withOpacity(0.5),
          borderRadius: 12.0,
        ),
      ],
    );
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
            isLoading: workflowState.status == DocumentWorkflowStatus.loading,
          ),
        ),
      ],
    );
  }

  void _validateAndSubmit() {
    // 폼 검증
    if (!_formKey.currentState!.validate()) {
      // 유효성 검사 실패
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필수 항목을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 서명 확인
    if (_signatureData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서명을 완료해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 동의 확인
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('개인정보 수집이용에 동의해주세요.'),
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

    // 데이터 수집
    final formData = {
      'name': _nameController.text,
      'address': _addressController.text,
      'agreed_to_terms': _agreedToTerms,
      'signature_date': DateTime.now().toIso8601String(),
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
      notifier.setDocumentCompleted('개인정보수집이용동의서', true);

      // 서명 URL 저장 (다른 문서에서 재사용할 수 있도록)
      if (_signatureData != null) {
        notifier.setSignatureUrl('signature_url_placeholder');
      }

      // 완료 콜백 호출
      widget.onCompleted();
    });
  }
}
