/// 대관 모델 클래스
/// 스튜디오 대관 정보를 표현
class RentalModel {
  /// 기본 생성자
  RentalModel({
    required this.id,
    required this.userId,
    required this.studioNumber,
    required this.rentalDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    this.companyName,
    this.userName,
    this.contactPhone,
    this.purpose,
    this.notes,
    this.equipmentRented,
    this.photoUploaded = false,
    this.equipmentReturned = false,
    this.updatedAt,
    this.completedAt,
  });

  /// JSON 데이터로부터 RentalModel 인스턴스 생성
  factory RentalModel.fromJson(Map<String, dynamic> json) {
    return RentalModel(
      id: json['id'],
      userId: json['user_id'],
      studioNumber: json['studio_number'],
      rentalDate: DateTime.parse(json['rental_date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: json['status'],
      companyName: json['company_name'],
      userName: json['user_name'],
      contactPhone: json['contact_phone'],
      purpose: json['purpose'],
      notes: json['notes'],
      equipmentRented: json['equipment_rented'],
      photoUploaded: json['photo_uploaded'] ?? false,
      equipmentReturned: json['equipment_returned'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : null,
    );
  }

  /// RentalModel 인스턴스를 JSON 데이터로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'studio_number': studioNumber,
      'rental_date':
          rentalDate.toIso8601String().split('T')[0], // YYYY-MM-DD 형식
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'company_name': companyName,
      'user_name': userName,
      'contact_phone': contactPhone,
      'purpose': purpose,
      'notes': notes,
      'equipment_rented': equipmentRented,
      'photo_uploaded': photoUploaded,
      'equipment_returned': equipmentReturned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// 대관 ID (UUID)
  final String id;

  /// 사용자 ID
  final String userId;

  /// 스튜디오 번호
  final String studioNumber;

  /// 대관 날짜
  final DateTime rentalDate;

  /// 시작 시간 (HH:MM 형식)
  final String startTime;

  /// 종료 시간 (HH:MM 형식)
  final String endTime;

  /// 대관 상태 (reserved, in_progress, completed, cancelled)
  final String status;

  /// 기업명
  final String? companyName;

  /// 사용자 이름
  final String? userName;

  /// 연락처
  final String? contactPhone;

  /// 대관 목적
  final String? purpose;

  /// 특이사항
  final String? notes;

  /// 대여 장비 정보 (JSON)
  final Map<String, dynamic>? equipmentRented;

  /// 사진 업로드 여부
  final bool photoUploaded;

  /// 장비 반납 여부
  final bool equipmentReturned;

  /// 생성 시간
  final DateTime createdAt;

  /// 수정 시간
  final DateTime? updatedAt;

  /// 완료 시간
  final DateTime? completedAt;

  /// 대관 중인지 여부
  bool get isInProgress => status == 'in_progress';

  /// 예약 상태인지 여부
  bool get isReserved => status == 'reserved';

  /// 완료 상태인지 여부
  bool get isCompleted => status == 'completed';

  /// 취소 상태인지 여부
  bool get isCancelled => status == 'cancelled';

  /// 대관 시간 문자열 (HH:MM ~ HH:MM 형식)
  String get timeRangeString => '$startTime ~ $endTime';

  /// 대관 일자 문자열 (YYYY년 MM월 DD일 형식)
  String get dateString {
    final year = rentalDate.year;
    final month = rentalDate.month;
    final day = rentalDate.day;
    return '$year년 $month월 $day일';
  }

  /// 업데이트된 정보로 새 인스턴스 생성
  RentalModel copyWith({
    String? id,
    String? userId,
    String? studioNumber,
    DateTime? rentalDate,
    String? startTime,
    String? endTime,
    String? status,
    String? companyName,
    String? userName,
    String? contactPhone,
    String? purpose,
    String? notes,
    Map<String, dynamic>? equipmentRented,
    bool? photoUploaded,
    bool? equipmentReturned,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return RentalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studioNumber: studioNumber ?? this.studioNumber,
      rentalDate: rentalDate ?? this.rentalDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      companyName: companyName ?? this.companyName,
      userName: userName ?? this.userName,
      contactPhone: contactPhone ?? this.contactPhone,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      equipmentRented: equipmentRented ?? this.equipmentRented,
      photoUploaded: photoUploaded ?? this.photoUploaded,
      equipmentReturned: equipmentReturned ?? this.equipmentReturned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
