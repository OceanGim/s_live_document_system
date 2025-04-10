/// 사용자 모델 클래스
/// Supabase에 저장된 사용자 정보를 표현
class UserModel {
  /// 기본 생성자
  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone = '',
    this.userType = '',
    required this.createdAt,
    this.role = 'user',
    this.companyName,
    this.isEmailConfirmed = false,
    this.lastSignedIn,
  });

  /// JSON 데이터로부터 UserModel 인스턴스 생성
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['user_type'] ?? '',
      role: json['role'] ?? 'user',
      companyName: json['company_name'],
      isEmailConfirmed: json['is_email_confirmed'] ?? false,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      lastSignedIn:
          json['last_signed_in'] != null
              ? DateTime.parse(json['last_signed_in'])
              : null,
    );
  }

  /// UserModel 인스턴스를 JSON 데이터로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'phone': phone,
      'user_type': userType,
      'role': role,
      'company_name': companyName,
      'is_email_confirmed': isEmailConfirmed,
      'created_at': createdAt.toIso8601String(),
      'last_signed_in': lastSignedIn?.toIso8601String(),
    };
  }

  /// 사용자 ID (UUID)
  final String id;

  /// 사용자 이메일
  final String email;

  /// 사용자 표시 이름
  final String displayName;

  /// 사용자 전화번호
  final String phone;

  /// 사용자 유형 (기업 또는 인플루언서)
  final String userType;

  /// 사용자 역할 (admin 또는 user)
  final String role;

  /// 기업명 (기업 사용자 경우)
  final String? companyName;

  /// 이메일 인증 여부
  final bool isEmailConfirmed;

  /// 계정 생성 시간
  final DateTime createdAt;

  /// 마지막 로그인 시간
  final DateTime? lastSignedIn;

  /// 사용자가 관리자인지 확인
  bool get isAdmin => role == 'admin';

  /// 사용자가 기업인지 확인
  bool get isCompany => userType == '기업';

  /// 사용자가 인플루언서인지 확인
  bool get isInfluencer => userType == '인플루언서';

  /// 업데이트된 정보로 새 인스턴스 생성
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phone,
    String? userType,
    String? role,
    String? companyName,
    bool? isEmailConfirmed,
    DateTime? createdAt,
    DateTime? lastSignedIn,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      role: role ?? this.role,
      companyName: companyName ?? this.companyName,
      isEmailConfirmed: isEmailConfirmed ?? this.isEmailConfirmed,
      createdAt: createdAt ?? this.createdAt,
      lastSignedIn: lastSignedIn ?? this.lastSignedIn,
    );
  }
}
