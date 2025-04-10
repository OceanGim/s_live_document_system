import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/models/document_model.dart';
import 'package:s_live_document_system/models/rental_model.dart';
import 'package:s_live_document_system/models/user_model.dart';
import 'package:s_live_document_system/providers/user_provider.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:uuid/uuid.dart';

/// 문서 작성 상태를 표현하는 열거형
enum DocumentWorkflowStatus {
  /// 진행 중
  inProgress,

  /// 완료됨
  completed,

  /// 취소됨
  cancelled,

  /// 오류 발생
  error,

  /// 로딩 중
  loading,

  /// 검토 중
  reviewing,
}

/// 문서 작성 프로세스를 담당하는 상태 객체
/// 문서 작성 흐름을 제어하고 진행 상황을 추적합니다.
class DocumentWorkflowState {
  /// 현재 진행 중인 단계
  final int currentStep;

  /// 렌탈 ID
  final String? rentalId;

  /// 각 문서의 완료 상태
  final Map<String, bool> completedDocuments;

  /// 서명 URL
  final String? signatureUrl;

  /// 출연자 목록 (초상권 동의서 작성용)
  final List<Map<String, dynamic>> performers;

  /// 워크플로우 상태
  final DocumentWorkflowStatus status;

  /// 기본 생성자
  DocumentWorkflowState({
    required this.currentStep,
    this.rentalId,
    required this.completedDocuments,
    this.signatureUrl,
    required this.performers,
    this.status = DocumentWorkflowStatus.inProgress,
  });

  /// 초기 상태 생성
  factory DocumentWorkflowState.initial() {
    return DocumentWorkflowState(
      currentStep: 0,
      rentalId: null,
      completedDocuments: {},
      signatureUrl: null,
      performers: [],
      status: DocumentWorkflowStatus.inProgress,
    );
  }

  /// 상태 복사본 생성
  DocumentWorkflowState copyWith({
    int? currentStep,
    String? rentalId,
    Map<String, bool>? completedDocuments,
    String? signatureUrl,
    List<Map<String, dynamic>>? performers,
    DocumentWorkflowStatus? status,
  }) {
    return DocumentWorkflowState(
      currentStep: currentStep ?? this.currentStep,
      rentalId: rentalId ?? this.rentalId,
      completedDocuments: completedDocuments ?? this.completedDocuments,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      performers: performers ?? this.performers,
      status: status ?? this.status,
    );
  }
}

/// 문서 워크플로우 파라미터 (각 문서 화면에서 사용)
class DocumentWorkflowProviderParams {
  /// 문서 유형
  final String documentType;

  /// 렌탈 ID
  final String? rentalId;

  /// 워크플로우 파라미터 생성자
  DocumentWorkflowProviderParams({required this.documentType, this.rentalId});
}

/// 문서 작성 프로세스 제공자
/// 문서 작성 흐름을 관리하고 문서 간 데이터를 공유합니다.
class DocumentWorkflowNotifier extends StateNotifier<DocumentWorkflowState> {
  final Ref ref;

  /// 문서 유형 목록
  static const List<String> documentTypes = [
    '개인정보수집이용동의서',
    '초상권이용동의서',
    '장비대여신청서',
    '시설이용자준수사항',
    '만족도조사',
  ];

  /// 기본 생성자
  DocumentWorkflowNotifier(this.ref) : super(DocumentWorkflowState.initial());

  /// 다음 단계로 진행
  void nextStep() {
    if (state.currentStep < documentTypes.length) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// 이전 단계로 돌아가기
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// 특정 단계로 이동
  void goToStep(int step) {
    if (step >= 0 && step <= documentTypes.length) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// 렌탈 ID 설정
  void setRentalId(String rentalId) {
    state = state.copyWith(rentalId: rentalId);
  }

  /// 서명 URL 설정
  void setSignatureUrl(String url) {
    state = state.copyWith(signatureUrl: url);
  }

  /// 문서 완료 상태 설정
  void setDocumentCompleted(String documentType, bool completed) {
    final updatedCompletedDocuments = Map<String, bool>.from(
      state.completedDocuments,
    );
    updatedCompletedDocuments[documentType] = completed;
    state = state.copyWith(completedDocuments: updatedCompletedDocuments);
  }

  /// 출연자 추가
  void addPerformer(Map<String, dynamic> performer) {
    final updatedPerformers = List<Map<String, dynamic>>.from(state.performers);
    updatedPerformers.add(performer);
    state = state.copyWith(performers: updatedPerformers);
  }

  /// 출연자 제거
  void removePerformer(int index) {
    if (index >= 0 && index < state.performers.length) {
      final updatedPerformers = List<Map<String, dynamic>>.from(
        state.performers,
      );
      updatedPerformers.removeAt(index);
      state = state.copyWith(performers: updatedPerformers);
    }
  }

  /// 출연자 업데이트
  void updatePerformer(int index, Map<String, dynamic> updatedPerformer) {
    if (index >= 0 && index < state.performers.length) {
      final updatedPerformers = List<Map<String, dynamic>>.from(
        state.performers,
      );
      updatedPerformers[index] = updatedPerformer;
      state = state.copyWith(performers: updatedPerformers);
    }
  }

  /// 워크플로우 상태 설정
  void setWorkflowStatus(DocumentWorkflowStatus status) {
    state = state.copyWith(status: status);
  }

  /// 워크플로우 초기화
  void reset() {
    state = DocumentWorkflowState.initial();
  }

  /// 모든 문서 완료 확인
  bool areAllDocumentsCompleted() {
    for (final documentType in documentTypes) {
      if (state.completedDocuments[documentType] != true) {
        return false;
      }
    }
    return true;
  }

  /// 사용자별 기존 문서 가져오기 (문서 스킵 기능용)
  Future<void> loadExistingDocuments() async {
    try {
      final user = ref.read(userInfoProvider);
      if (user == null) return;

      // 기존 문서 확인
      final documents = await getDocumentsForUser(user.id);
      if (documents.isEmpty) return;

      // 문서 유형별로 완료 상태 업데이트
      final updatedCompletedDocuments = Map<String, bool>.from(
        state.completedDocuments,
      );

      for (final documentType in documentTypes) {
        // 개인정보수집이용동의서 또는 시설이용자준수사항은 기존에 완료된 것이 있으면 완료로 표시
        // 초상권이용동의서, 장비대여신청서, 만족도조사는 매번 새로 작성
        if (documentType == '개인정보수집이용동의서' || documentType == '시설이용자준수사항') {
          final completed = documents.any(
            (doc) =>
                doc.documentType == documentType && doc.status == 'completed',
          );

          if (completed) {
            updatedCompletedDocuments[documentType] = true;
            Logger.info(
              '기존 문서 발견: $documentType - 스킵됨',
              tag: 'DocumentWorkflow',
            );
          }
        }
      }

      state = state.copyWith(completedDocuments: updatedCompletedDocuments);

      // 서명 URL도 가져오기
      if (state.signatureUrl == null) {
        final signedDoc = documents.firstWhere(
          (doc) => doc.signatureUrl != null && doc.signatureUrl!.isNotEmpty,
          orElse:
              () => DocumentModel(
                id: '',
                userId: '',
                documentType: '',
                status: '',
                createdAt: DateTime.now(),
              ),
        );

        if (signedDoc.signatureUrl != null &&
            signedDoc.signatureUrl!.isNotEmpty) {
          state = state.copyWith(signatureUrl: signedDoc.signatureUrl);
          Logger.info(
            '기존 서명 발견: ${signedDoc.signatureUrl}',
            tag: 'DocumentWorkflow',
          );
        }
      }
    } catch (e, stack) {
      Logger.error(
        '기존 문서 로드 오류',
        error: e,
        stackTrace: stack,
        tag: 'DocumentWorkflow',
      );
    }
  }

  /// 사용자 문서 목록 조회 (임시 메서드, 실제로는 DocumentProvider를 통해 처리해야 함)
  Future<List<DocumentModel>> getDocumentsForUser(String userId) async {
    // 해당 사용자의 문서들을 가져오는 로직이 필요함
    // 여기서는 임시로 빈 목록 반환, 실제 구현 필요
    return [];
  }

  /// 현재 문서 유형 가져오기
  String getCurrentDocumentType() {
    if (state.currentStep < 0 || state.currentStep >= documentTypes.length) {
      return '';
    }
    return documentTypes[state.currentStep];
  }

  /// 워크플로우 진행 가능 상태 확인
  Future<bool> validateWorkflowState() async {
    // 렌탈 ID가 없으면 안됨
    if (state.rentalId == null || state.rentalId!.isEmpty) {
      return false;
    }

    // 렌탈 정보 확인 로직이 필요함
    // 실제로는 RentalProvider를 통해 처리해야 함
    return true;
  }

  /// 다음 필요한 문서로 점프
  void jumpToNextRequiredDocument() {
    // 현재 단계부터 순차적으로 확인하여 완료되지 않은 첫 번째 문서로 이동
    for (int i = 0; i < documentTypes.length; i++) {
      final documentType = documentTypes[i];
      if (state.completedDocuments[documentType] != true) {
        state = state.copyWith(currentStep: i);
        return;
      }
    }

    // 모든 문서가 완료되었다면 마지막 단계로 이동
    state = state.copyWith(
      currentStep: documentTypes.length,
      status: DocumentWorkflowStatus.completed,
    );
  }
}

/// 문서 작성 프로세스 제공자
final documentWorkflowProvider =
    StateNotifierProvider<DocumentWorkflowNotifier, DocumentWorkflowState>(
      (ref) => DocumentWorkflowNotifier(ref),
    );
