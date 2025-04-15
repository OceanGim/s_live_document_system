import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/constants/app_colors.dart';
import 'package:s_live_document_system/models/equipment_model.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/providers/document_workflow_provider.dart';
import 'package:s_live_document_system/providers/equipment_provider.dart';
import 'package:s_live_document_system/services/signature_service.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:s_live_document_system/widgets/signature_canvas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 장비 대여 신청 폼
/// 스튜디오 이용에서 필요한 장비를 대여 신청하는 폼입니다.
class EquipmentRentalForm extends ConsumerStatefulWidget {
  /// 기본 생성자
  const EquipmentRentalForm({
    super.key,
    required this.onCompleted,
    required this.providerParams,
  });

  /// 완료 콜백
  final VoidCallback onCompleted;

  /// 워크플로우 파라미터
  final DocumentWorkflowProviderParams providerParams;

  @override
  ConsumerState<EquipmentRentalForm> createState() =>
      _EquipmentRentalFormState();
}

class _EquipmentRentalFormState extends ConsumerState<EquipmentRentalForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _autovalidate = false;
  Uint8List? _signatureData;
  bool _hasSavedSignature = false;
  Uint8List? _savedSignatureData;
  final SignatureService _signatureService = SignatureService();

  // 고정 장비 목록
  final Map<String, Map<String, dynamic>> _equipmentList = {
    'camera': {'name': '카메라', 'max': 3, 'unit': '대'},
    'camera_tripod': {'name': '카메라삼각대', 'max': 3, 'unit': '대'},
    'mobile_tripod': {'name': '모바일 삼각대', 'max': 2, 'unit': '대'},
    'panel_light': {'name': '판조명', 'max': 6, 'unit': '대'},
    'ring_light': {'name': '링조명', 'max': 6, 'unit': '대'},
    'aputure_light': {'name': '어퓨쳐조명', 'max': 2, 'unit': '대'},
    'light_tripod': {'name': '조명삼각대', 'max': 14, 'unit': '대'},
    'tripod': {'name': '삼각대 달리', 'max': 2, 'unit': '대'},
    'switcher': {'name': '스위쳐', 'max': 1, 'unit': '대'},
    'capture_board': {'name': '캡쳐보드', 'max': 2, 'unit': '대'},
    'hdmi_splitter': {'name': 'HDMI분배기', 'max': 1, 'unit': '대'},
    'wireless_mic': {'name': '무선마이크', 'max': 5, 'unit': '개'},
    'multi_tap': {'name': '멀티탭', 'max': 5, 'unit': '개'},
    'reel_cable': {'name': '릴선', 'max': 1, 'unit': '개'},
    'hdmi_cable': {'name': 'HDMI 케이블', 'max': 6, 'unit': '개'},
  };

  // 선택된 장비 목록
  final Map<String, int> _selectedEquipment = {};

  @override
  void initState() {
    super.initState();
    // 저장된 서명 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedSignature();
    });
  }

  // 저장된 서명 불러오기
  Future<void> _loadSavedSignature() async {
    try {
      setState(() => _isSubmitting = true);

      final signature = await _signatureService.getCurrentUserSignature();
      if (signature != null) {
        setState(() {
          _savedSignatureData = signature;
          _hasSavedSignature = true;
          _signatureData = signature; // 자동으로 서명 입력
        });

        Logger.info('저장된 서명 불러오기 성공', tag: 'EquipmentRentalForm');
      }
    } catch (e) {
      Logger.error('서명 불러오기 오류', error: e, tag: 'EquipmentRentalForm');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode:
              _autovalidate
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '장비 대여 신청서',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '이용하실 장비를 선택해주세요. '
                        '장비 파손시 동일 제품으로 구매해주셔야합니다. 장비 대여 신청서 제출시 이에 동의하시는 것으로 간주합니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 장비 선택
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '장비 선택',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '대여할 장비를 선택하고 수량을 입력해주세요. '
                        '수량이 0인 장비는 대여하지 않는 것으로 간주됩니다.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ..._equipmentList.entries.map(
                        (entry) => _buildFixedEquipmentItem(
                          entry.key,
                          entry.value['name'] as String,
                          entry.value['max'] as int,
                          entry.value['unit'] as String,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 제출 버튼
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitEquipmentRental,
                icon:
                    _isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.check_circle),
                label: const Text('장비 대여 신청서 제출하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 고정 장비 아이템 위젯
  Widget _buildFixedEquipmentItem(
    String id,
    String name,
    int maxQuantity,
    String unit,
  ) {
    int selectedQuantity = _selectedEquipment[id] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '최대 $maxQuantity$unit까지 대여 가능',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed:
                      selectedQuantity <= 0
                          ? null
                          : () {
                            setState(() {
                              _selectedEquipment[id] = selectedQuantity - 1;
                            });
                          },
                ),
                Text(
                  '$selectedQuantity',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed:
                      selectedQuantity >= maxQuantity
                          ? null
                          : () {
                            setState(() {
                              _selectedEquipment[id] = selectedQuantity + 1;
                            });
                          },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 장비 아이템 위젯
  Widget _buildEquipmentItem(EquipmentModel equipment) {
    int selectedQuantity = _selectedEquipment[equipment.id] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '대여 가능: ${equipment.availableQuantity}대',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed:
                      selectedQuantity <= 0
                          ? null
                          : () {
                            setState(() {
                              if (selectedQuantity > 0) {
                                _selectedEquipment[equipment.id] =
                                    selectedQuantity - 1;
                              }
                            });
                          },
                ),
                Text(
                  '$selectedQuantity',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed:
                      (equipment.availableQuantity ?? 0) <= selectedQuantity
                          ? null
                          : () {
                            setState(() {
                              _selectedEquipment[equipment.id] =
                                  selectedQuantity + 1;
                            });
                          },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 장비 대여 신청서 제출
  Future<void> _submitEquipmentRental() async {
    // 폼 검증
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autovalidate = true;
      });
      return;
    }

    // 장비 선택 여부 확인
    final selectedEquipmentCount =
        _selectedEquipment.entries.where((entry) => entry.value > 0).length;

    if (selectedEquipmentCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개 이상의 장비를 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = ref.read(authProvider);
      final userId = authState.userId;

      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 선택된 장비 정보 가져오기
      final equipmentDetails = <Map<String, dynamic>>[];

      for (final entry in _selectedEquipment.entries) {
        if (entry.value > 0) {
          final equipmentId = entry.key;
          final quantity = entry.value;

          // 장비 정보 조회
          final equipmentData = await ref.read(
            equipmentProvider(equipmentId).future,
          );

          if (equipmentData != null) {
            equipmentDetails.add({
              'equipment_id': equipmentId,
              'name': equipmentData.name,
              'category': equipmentData.category,
              'quantity': quantity,
              'rent_fee': equipmentData.rentFee,
              'deposit_fee': equipmentData.depositFee,
            });
          }
        }
      }

      // 워크플로우에서 시간 데이터 가져오기
      final workflowState = ref.read(documentWorkflowProvider);
      final Map<String, dynamic> formData = workflowState.formData ?? {};

      // 제출 데이터 준비
      final rentalData = {
        'user_id': userId,
        'document_type': 'equipment_rental',
        'status': 'submitted',
        'metadata': {
          'start_time': formData['start_time'],
          'end_time': formData['end_time'],
          'equipment_details': equipmentDetails,
          'submitted_at': DateTime.now().toIso8601String(),
        },
        'created_at': DateTime.now().toIso8601String(),
        'submitted_at': DateTime.now().toIso8601String(),
      };

      // Supabase에 저장
      final response =
          await Supabase.instance.client
              .from('documents')
              .insert(rentalData)
              .select();

      Logger.info('장비 대여 신청서 제출 완료: $response');

      // 완료 콜백 호출
      widget.onCompleted();
    } catch (e, stack) {
      Logger.error('장비 대여 신청서 제출 오류', error: e, stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
