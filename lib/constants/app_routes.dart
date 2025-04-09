/// 앱 내 라우트 경로 정의
class AppRoutes {
  // 인증 관련 경로
  static const String login = '/login';
  static const String register = '/register';

  // 홈 화면
  static const String home = '/home';

  // 사용자 화면
  static const String userHome = '/user/home';
  static const String rentalTimeInput = '/user/rental_time';

  // 문서 작성 화면
  static const String personalInfoForm = '/user/documents/personal_info';
  static const String portraitRightsForm = '/user/documents/portrait_rights';
  static const String equipmentRentalForm = '/user/documents/equipment_rental';
  static const String facilityGuidelinesForm =
      '/user/documents/facility_guidelines';
  static const String satisfactionSurveyForm =
      '/user/documents/satisfaction_survey';
  static const String documentComplete = '/user/documents/complete';

  // 관리자 화면
  static const String adminHome = '/admin/home';
  static const String documentReview = '/admin/document_review';
  static const String equipmentReturn = '/admin/equipment_return';
  static const String photoUpload = '/admin/photo_upload';
  static const String adminSignatures = '/admin/signatures';

  // 파라미터를 받는 경로 생성 도우미
  static String documentReviewWithId(String userId) =>
      '$documentReview/$userId';
  static String equipmentReturnWithId(String userId) =>
      '$equipmentReturn/$userId';
  static String photoUploadWithId(String rentalId) => '$photoUpload/$rentalId';
}
