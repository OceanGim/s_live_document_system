/// 문서 모델 클래스
/// Supabase에 저장된 문서 정보를 표현
class DocumentModel {
  /// 기본 생성자
  DocumentModel({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.status,
    required this.createdAt,
    this.fileName,
    this.filePath,
    this.fileUrl,
    this.metadata,
    this.submittedAt,
    this.updatedAt,
    this.signatureUrl,
  });

  /// JSON 데이터로부터 DocumentModel 인스턴스 생성
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      userId: json['user_id'],
      documentType: json['document_type'],
      status: json['status'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      fileUrl: json['file_url'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
      submittedAt:
          json['submitted_at'] != null
              ? DateTime.parse(json['submitted_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      signatureUrl: json['signature_url'],
    );
  }

  /// DocumentModel 인스턴스를 JSON 데이터로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'document_type': documentType,
      'status': status,
      'file_name': fileName,
      'file_path': filePath,
      'file_url': fileUrl,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'signature_url': signatureUrl,
    };
  }

  /// 문서 ID (UUID)
  final String id;

  /// 소유자 ID (사용자 ID)
  final String userId;

  /// 문서 유형 (개인정보동의서, 초상권이용동의서 등)
  final String documentType;

  /// 문서 상태 (제출, 대기, 미제출)
  final String status;

  /// 파일명
  final String? fileName;

  /// 파일 경로
  final String? filePath;

  /// 파일 URL
  final String? fileUrl;

  /// 문서 메타데이터 (JSON)
  final Map<String, dynamic>? metadata;

  /// 문서 생성 시간
  final DateTime createdAt;

  /// 문서 제출 시간
  final DateTime? submittedAt;

  /// 문서 수정 시간
  final DateTime? updatedAt;

  /// 서명 이미지 URL
  final String? signatureUrl;

  /// 제출 완료 여부
  bool get isSubmitted => status == 'submitted';

  /// 대기 중 여부
  bool get isPending => status == 'pending';

  /// 미제출 여부
  bool get isMissing => status == 'missing';

  /// 문서 유형명 (한글)
  String get documentTypeName {
    switch (documentType) {
      case 'personal_info':
        return '개인정보 수집이용 동의서';
      case 'portrait_rights':
        return '초상권 이용 동의서';
      case 'equipment_rental':
        return '장비 대여 신청서';
      case 'facility_guidelines':
        return '스튜디오 시설 이용자 준수사항';
      case 'satisfaction_survey':
        return '만족도 조사';
      default:
        return documentType;
    }
  }

  /// 업데이트된 정보로 새 인스턴스 생성
  DocumentModel copyWith({
    String? id,
    String? userId,
    String? documentType,
    String? status,
    String? fileName,
    String? filePath,
    String? fileUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? submittedAt,
    DateTime? updatedAt,
    String? signatureUrl,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      documentType: documentType ?? this.documentType,
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      signatureUrl: signatureUrl ?? this.signatureUrl,
    );
  }
}
