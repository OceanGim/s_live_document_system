import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 색상 상수 모음
class AppColors {
  // 기본 색상
  static const Color primary = Color(0xFF0071BD); // 메인 색상 (S-LIVE 로고 색상)
  static const Color secondary = Color(0xFF4E8AF4); // 보조 색상
  static const Color accent = Color(0xFF69B1FF); // 강조 색상

  // 테마 색상
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF7F7F7);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // 텍스트 색상
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textLight = Colors.white;

  // 경계선 및 구분선 색상
  static const Color border = Color(0xFFDDDDDD);
  static const Color divider = Color(0xFFEEEEEE);

  // 상태 색상
  static const Color studioAvailable = Color(0xFF81C784); // 이용 가능
  static const Color studioBooked = Color(0xFFFFA726); // 예약됨
  static const Color studioUnavailable = Color(0xFFEF5350); // 이용 불가

  // 서류 상태 색상
  static const Color documentSubmitted = Color(0xFF81C784); // 제출됨
  static const Color documentPending = Color(0xFFFFA726); // 대기 중
  static const Color documentMissing = Color(0xFFEF5350); // 미제출

  // 미배정 카드 바탕색
  static const Color cardBackground = Color(0xFFF5F5F5);
  static const Color cardShadow = Color(0x1F000000);
}
