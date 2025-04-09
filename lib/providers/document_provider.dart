import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/models/document_model.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 사용자별 문서 목록을 위한 Provider
final userDocumentsProvider =
    FutureProvider.family<List<DocumentModel>, String>((ref, userId) async {
      // 사용자 ID가 없으면 빈 목록 반환
      if (userId.isEmpty) {
        return [];
      }

      try {
        Logger.info('사용자 문서 목록 조회 시작: $userId', tag: 'DocumentProvider');

        // 문서 테이블에서 사용자별 문서 조회
        final documentsData = await Supabase.instance.client
            .from('documents')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        // DocumentModel 리스트로 변환
        final documents =
            documentsData.map((data) => DocumentModel.fromJson(data)).toList();

        Logger.info(
          '사용자 문서 목록 조회 완료: ${documents.length}개',
          tag: 'DocumentProvider',
        );
        return documents;
      } catch (e, stack) {
        Logger.error(
          '사용자 문서 목록 조회 실패',
          error: e,
          stackTrace: stack,
          tag: 'DocumentProvider',
        );
        return [];
      }
    });

/// 현재 로그인한 사용자의 문서 목록을 위한 Provider
final currentUserDocumentsProvider = FutureProvider<List<DocumentModel>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  final userId = authState.userId;

  if (userId == null) {
    return [];
  }

  return ref.watch(userDocumentsProvider(userId).future);
});

/// 문서 유형별로 필터링된 사용자 문서 목록을 위한 Provider
final filteredUserDocumentsProvider =
    Provider.family<List<DocumentModel>, FilterParams>((ref, params) {
      final asyncDocuments = ref.watch(userDocumentsProvider(params.userId));

      return asyncDocuments.when(
        data: (documents) {
          // 필터링 조건이 없으면 전체 목록 반환
          if (params.documentType.isEmpty && params.status.isEmpty) {
            return documents;
          }

          // 필터링 조건에 따라 필터링
          return documents.where((doc) {
            bool typeMatches =
                params.documentType.isEmpty ||
                doc.documentType == params.documentType;
            bool statusMatches =
                params.status.isEmpty || doc.status == params.status;
            return typeMatches && statusMatches;
          }).toList();
        },
        loading: () => [],
        error: (_, __) => [],
      );
    });

/// 필터링 파라미터 클래스
class FilterParams {
  final String userId;
  final String documentType;
  final String status;

  FilterParams({
    required this.userId,
    this.documentType = '',
    this.status = '',
  });
}

/// 문서 관리를 위한 Provider
final documentProvider =
    StateNotifierProvider<DocumentNotifier, AsyncValue<DocumentModel?>>((ref) {
      return DocumentNotifier();
    });

/// 문서 관리 Notifier
class DocumentNotifier extends StateNotifier<AsyncValue<DocumentModel?>> {
  DocumentNotifier() : super(const AsyncValue.loading());

  /// 문서 조회
  Future<void> fetchDocument(String documentId) async {
    state = const AsyncValue.loading();

    try {
      Logger.info('문서 조회 시작: $documentId', tag: 'DocumentNotifier');

      // 문서 조회
      final documentData =
          await Supabase.instance.client
              .from('documents')
              .select()
              .eq('id', documentId)
              .single();

      if (documentData != null) {
        // DocumentModel로 변환
        final document = DocumentModel.fromJson(documentData);
        state = AsyncValue.data(document);
        Logger.info('문서 조회 완료', tag: 'DocumentNotifier');
      } else {
        state = const AsyncValue.data(null);
        Logger.warning('문서를 찾을 수 없음: $documentId', tag: 'DocumentNotifier');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Logger.error(
        '문서 조회 실패',
        error: e,
        stackTrace: stack,
        tag: 'DocumentNotifier',
      );
    }
  }

  /// 새 문서 생성
  Future<DocumentModel?> createDocument({
    required String userId,
    required String documentType,
    String? fileName,
    String? filePath,
    Map<String, dynamic>? metadata,
    String status = 'pending',
  }) async {
    try {
      Logger.info('새 문서 생성 시작', tag: 'DocumentNotifier');

      // 새 문서 데이터 준비
      final Map<String, dynamic> documentData = {
        'user_id': userId,
        'document_type': documentType,
        'status': status,
        'file_name': fileName,
        'file_path': filePath,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      };

      // 문서 생성
      final result =
          await Supabase.instance.client
              .from('documents')
              .insert(documentData)
              .select()
              .single();

      // DocumentModel로 변환
      final document = DocumentModel.fromJson(result);
      state = AsyncValue.data(document);

      Logger.info('새 문서 생성 완료: ${document.id}', tag: 'DocumentNotifier');
      return document;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Logger.error(
        '새 문서 생성 실패',
        error: e,
        stackTrace: stack,
        tag: 'DocumentNotifier',
      );
      return null;
    }
  }

  /// 문서 업데이트
  Future<bool> updateDocument(
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      Logger.info('문서 업데이트 시작: $documentId', tag: 'DocumentNotifier');

      // 업데이트 데이터에 수정 시간 추가
      final updateData = {
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 문서 업데이트
      await Supabase.instance.client
          .from('documents')
          .update(updateData)
          .eq('id', documentId);

      // 업데이트 후 문서 조회
      await fetchDocument(documentId);

      Logger.info('문서 업데이트 완료', tag: 'DocumentNotifier');
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Logger.error(
        '문서 업데이트 실패',
        error: e,
        stackTrace: stack,
        tag: 'DocumentNotifier',
      );
      return false;
    }
  }

  /// 문서 제출 완료로 표시
  Future<bool> submitDocument(String documentId, String? signatureUrl) async {
    try {
      Logger.info('문서 제출 처리 시작: $documentId', tag: 'DocumentNotifier');

      // 제출 데이터 준비
      final submitData = {
        'status': 'submitted',
        'submitted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'signature_url': signatureUrl,
      };

      // 문서 업데이트
      await Supabase.instance.client
          .from('documents')
          .update(submitData)
          .eq('id', documentId);

      // 업데이트 후 문서 조회
      await fetchDocument(documentId);

      Logger.info('문서 제출 처리 완료', tag: 'DocumentNotifier');
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Logger.error(
        '문서 제출 처리 실패',
        error: e,
        stackTrace: stack,
        tag: 'DocumentNotifier',
      );
      return false;
    }
  }

  /// 문서 서명 업로드
  Future<String?> uploadSignature(
    String documentId,
    Uint8List signatureBytes,
  ) async {
    try {
      Logger.info('문서 서명 업로드 시작: $documentId', tag: 'DocumentNotifier');

      // 스토리지 경로 생성
      final String path = 'signatures/$documentId.png';

      // 서명 이미지 업로드
      await Supabase.instance.client.storage
          .from('documents')
          .uploadBinary(path, signatureBytes);

      // 서명 이미지 URL 가져오기
      final String signatureUrl = Supabase.instance.client.storage
          .from('documents')
          .getPublicUrl(path);

      Logger.info('문서 서명 업로드 완료', tag: 'DocumentNotifier');
      return signatureUrl;
    } catch (e, stack) {
      Logger.error(
        '문서 서명 업로드 실패',
        error: e,
        stackTrace: stack,
        tag: 'DocumentNotifier',
      );
      return null;
    }
  }

  /// 문서 파일 업로드
  Future<String?> uploadDocument(
    String documentId,
    String fileName,
    Uint8List fileBytes,
  ) async {
    try {
      Logger.info('문서 파일 업로드 시작: $documentId', tag: 'DocumentNotifier');

      // 스토리지 경로 생성
      final String path = 'documents/$documentId/$fileName';

      // 문서 파일 업로드
      await Supabase.instance.client.storage
          .from('documents')
          .uploadBinary(path, fileBytes);

      // 문서 파일 URL 가져오기
      final String fileUrl = Supabase.instance.client.storage
          .from('documents')
          .getPublicUrl(path);

      // 문서 정보 업데이트
      await updateDocument(documentId, {
        'file_name': fileName,
        'file_path': path,
        'file_url': fileUrl,
      });

      Logger.info('문서 파일 업로드 완료', tag: 'DocumentNotifier');
      return fileUrl;
    } catch (e, stack) {
      Logger.error(
        '문서 파일 업로드 실패',
        error: e,
        stackTrace: stack,
        tag: 'DocumentNotifier',
      );
      return null;
    }
  }
}

/// 문서 템플릿 Provider
final documentTemplatesProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  try {
    Logger.info('문서 템플릿 목록 조회 시작', tag: 'DocumentTemplatesProvider');

    // 문서 템플릿 조회
    final templatesData = await Supabase.instance.client
        .from('document_templates')
        .select()
        .order('document_type');

    // 템플릿 맵으로 변환
    final Map<String, String> templates = {};
    for (final template in templatesData) {
      templates[template['document_type']] = template['content'];
    }

    Logger.info(
      '문서 템플릿 목록 조회 완료: ${templates.length}개',
      tag: 'DocumentTemplatesProvider',
    );
    return templates;
  } catch (e, stack) {
    Logger.error(
      '문서 템플릿 목록 조회 실패',
      error: e,
      stackTrace: stack,
      tag: 'DocumentTemplatesProvider',
    );
    return {};
  }
});
