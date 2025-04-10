import 'package:supabase_flutter/supabase_flutter.dart';

/// 사용자 모델
/// 로그인한 사용자 정보를 저장합니다.
class UserModel {
  /// 사용자 ID
  final String id;

  /// 이메일
  final String? email;

  /// 표시 이름
  final String? displayName;

  /// 사용자 역할 (admin, user)
  final String? role;

  /// 전화번호
  final String? phone;

  /// 사용자 서명 URL
  final String? signatureUrl;

  /// 기업 또는 인플루언서 구분
  final String? userType; // 'company' 또는 'influencer'

  /// 기업 정보 (userType이 'company'인 경우)
  final Map<String, dynamic>? companyInfo;

  /// 인플루언서 정보 (userType이 'influencer'인 경우)
  final Map<String, dynamic>? influencerInfo;

  /// 계정 생성 시각
  final DateTime? createdAt;

  /// 마지막 로그인 시각
  final DateTime? lastSignInAt;

  /// 계정 업데이트 시각
  final DateTime? updatedAt;

  /// 추가 메타데이터
  final Map<String, dynamic>? metadata;

  /// 사용자 아바타 URL
  final String? avatarUrl;

  /// 기본 생성자
  UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.role,
    this.phone,
    this.signatureUrl,
    this.userType,
    this.companyInfo,
    this.influencerInfo,
    this.createdAt,
    this.lastSignInAt,
    this.updatedAt,
    this.metadata,
    this.avatarUrl,
  });

  /// 빈 사용자 생성
  factory UserModel.empty() {
    return UserModel(id: '');
  }

  /// JSON에서 UserModel 생성
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      role: json['role'] as String?,
      phone: json['phone'] as String?,
      signatureUrl: json['signature_url'] as String?,
      userType: json['user_type'] as String?,
      companyInfo:
          json['company_info'] != null
              ? Map<String, dynamic>.from(json['company_info'] as Map)
              : null,
      influencerInfo:
          json['influencer_info'] != null
              ? Map<String, dynamic>.from(json['influencer_info'] as Map)
              : null,
      createdAt: _parseDateTime(json['created_at']),
      lastSignInAt: _parseDateTime(json['last_sign_in_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      metadata:
          json['metadata'] != null
              ? Map<String, dynamic>.from(json['metadata'] as Map)
              : null,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  /// Supabase User와 Profile 정보에서 UserModel 생성
  factory UserModel.fromUserAndProfile(
    User user,
    Map<String, dynamic>? profile,
  ) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName:
          profile?['display_name'] as String? ??
          user.userMetadata?['name'] as String?,
      role: profile?['role'] as String?,
      phone: profile?['phone'] as String? ?? user.phone,
      signatureUrl: profile?['signature_url'] as String?,
      userType: profile?['user_type'] as String?,
      companyInfo:
          profile != null && profile['company_info'] != null
              ? Map<String, dynamic>.from(profile['company_info'] as Map)
              : null,
      influencerInfo:
          profile != null && profile['influencer_info'] != null
              ? Map<String, dynamic>.from(profile['influencer_info'] as Map)
              : null,
      createdAt: _parseDateTime(user.createdAt),
      lastSignInAt: _parseDateTime(user.lastSignInAt),
      updatedAt: _parseDateTime(user.updatedAt),
      metadata: user.userMetadata,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  /// UserModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role,
      'phone': phone,
      'signature_url': signatureUrl,
      'user_type': userType,
      'company_info': companyInfo,
      'influencer_info': influencerInfo,
      'created_at': createdAt?.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'avatar_url': avatarUrl,
    };
  }

  /// UserModel 복사본 생성 (필드 변경 가능)
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? role,
    String? phone,
    String? signatureUrl,
    String? userType,
    Map<String, dynamic>? companyInfo,
    Map<String, dynamic>? influencerInfo,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      userType: userType ?? this.userType,
      companyInfo: companyInfo ?? this.companyInfo,
      influencerInfo: influencerInfo ?? this.influencerInfo,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'UserModel{id: $id, email: $email, displayName: $displayName, role: $role}';
  }

  /// 관리자 여부 확인
  bool get isAdmin => role == 'admin';

  /// 기업 사용자 여부 확인
  bool get isCompany => userType == 'company';

  /// 인플루언서 사용자 여부 확인
  bool get isInfluencer => userType == 'influencer';

  /// 기업명 획득
  String get companyName =>
      isCompany &&
              companyInfo != null &&
              companyInfo!.containsKey('company_name')
          ? companyInfo!['company_name'] as String? ?? ''
          : '';

  /// 마지막 로그인 시각 (lastSignInAt의 별칭)
  DateTime? get lastSignedIn => lastSignInAt;

  /// DateTime 문자열 파싱 헬퍼 메서드
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }
}
