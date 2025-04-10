import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:gsheets/gsheets.dart';
import 'package:s_live_document_system/models/document_model.dart';
import 'package:s_live_document_system/models/equipment_model.dart';
import 'package:s_live_document_system/models/rental_model.dart';
import 'package:s_live_document_system/models/rental_model_extensions.dart';
import 'package:s_live_document_system/models/user_model.dart';
import 'package:s_live_document_system/utils/date_formatter.dart';
import 'package:s_live_document_system/utils/logger.dart';

/// 요구사항에 맞는 S-Live 스튜디오 문서 시스템의 Google Sheets 내보내기 서비스
///
/// 다음 세 가지 시트 유형에 맞게 데이터를 내보냅니다:
/// 1. 라이브커머스 시트
/// 2. 일반대관 시트
/// 3. 만족도 조사 시트
class GSheetsExportService {
  static GSheetsExportService? _instance;
  late GSheets _gsheets;
  Spreadsheet? _spreadsheet;

  // 스프레드시트 ID
  String? _spreadsheetId;

  // 각 특수 워크시트 캐시
  Worksheet? _liveCommerceSheet;
  Worksheet? _normalRentalSheet;
  Worksheet? _satisfactionSurveySheet;

  /// 싱글톤 인스턴스 반환
  factory GSheetsExportService() {
    _instance ??= GSheetsExportService._internal();
    return _instance!;
  }

  GSheetsExportService._internal();

  /// Google Sheets API 초기화
  Future<bool> init() async {
    try {
      // 환경 변수 또는 assets에서 Google Sheets API 키 로드
      final credentials = await _loadCredentials();
      _gsheets = GSheets(credentials);

      // 환경 설정에서 스프레드시트 ID 로드
      _spreadsheetId = await _loadSpreadsheetId();

      if (_spreadsheetId == null) {
        Logger.error(
          'GSheetsExportService: 스프레드시트 ID를 찾을 수 없습니다.',
          tag: 'GSheetsExportService',
        );
        return false;
      }

      // 스프레드시트 연결
      _spreadsheet = await _gsheets.spreadsheet(_spreadsheetId!);

      // 워크시트 준비
      await _prepareWorksheets();

      return true;
    } catch (e) {
      Logger.error(
        'GSheetsExportService 초기화 오류: $e',
        tag: 'GSheetsExportService',
      );
      return false;
    }
  }

  /// 자격 증명(Credentials) 로드
  Future<String> _loadCredentials() async {
    try {
      // assets에서 JSON 파일 로드
      return await rootBundle.loadString(
        'assets/google_sheets_credentials.json',
      );
    } catch (e) {
      // 환경 변수에서 직접 읽기 (테스트용)
      try {
        final envJson = await rootBundle.loadString('assets/env.json');
        final envData = jsonDecode(envJson) as Map<String, dynamic>;
        return envData['GOOGLE_SHEETS_CREDENTIALS'] as String;
      } catch (e2) {
        throw Exception('Google Sheets 자격 증명을 로드할 수 없습니다: $e2');
      }
    }
  }

  /// 스프레드시트 ID 로드
  Future<String?> _loadSpreadsheetId() async {
    try {
      final envJson = await rootBundle.loadString('assets/env.json');
      final envData = jsonDecode(envJson) as Map<String, dynamic>;
      return envData['GOOGLE_SHEETS_ID'] as String?;
    } catch (e) {
      Logger.error('스프레드시트 ID 로드 오류: $e', tag: 'GSheetsExportService');
      return null;
    }
  }

  /// 필요한 워크시트 준비
  Future<void> _prepareWorksheets() async {
    if (_spreadsheet == null) return;

    // 1. 라이브커머스 시트 준비
    _liveCommerceSheet = await _getOrCreateWorksheet('라이브커머스_대관', [
      '방송날짜',
      '요일',
      '방송시작시간',
      '대여시작/종료',
      '스튜디오',
      '사용자유형',
      '기업명',
      '사업자번호',
      '브랜드명',
      '상품명',
      '상품수',
      '카테고리',
      '서울중소기업여부',
      '담당자명',
      '쇼호스트명',
      '시청자수',
      '매출액',
      '장비 리스트',
      '송출채널',
      '비고',
    ]);

    // 2. 일반대관 시트 준비
    _normalRentalSheet = await _getOrCreateWorksheet('일반대관', [
      '대관일자',
      '요일',
      '대여시작/종료',
      '스튜디오',
      '사용자유형',
      '기업명',
      '사업자번호',
      '상품명',
      '카테고리',
      '담당자',
      '장비 리스트',
      '기타',
    ]);

    // 3. 만족도 조사 시트 준비
    _satisfactionSurveySheet = await _getOrCreateWorksheet('만족도조사', [
      '기업명(인플루언서명)',
      '대관일자',
      '스튜디오',
      '이용목적',
      '시설만족도',
      '직원친절도',
      '장비전문성',
      '예약만족도',
      '청결상태',
      '장비품질',
      '스튜디오경로',
      '이점',
      '시청자수',
      '매출액',
      '기타의견',
      '후속조치내용',
      '처리여부',
      '비고',
    ]);
  }

  /// 워크시트 가져오기 또는 생성 (문서용 - 확장 모듈에서 사용)
  Future<Worksheet> getOrCreateDocumentWorksheet(
    String title,
    List<String> headers,
  ) async {
    return _getOrCreateWorksheet(title, headers);
  }

  /// 워크시트 가져오기 또는 생성 (내부용)
  Future<Worksheet> _getOrCreateWorksheet(
    String title,
    List<String> headers,
  ) async {
    if (_spreadsheet == null) {
      throw Exception('스프레드시트가 초기화되지 않았습니다');
    }

    // 기존 워크시트 찾기
    var worksheet = _spreadsheet!.worksheetByTitle(title);

    // 없으면 새로 생성
    if (worksheet == null) {
      worksheet = await _spreadsheet!.addWorksheet(title);

      // 헤더 설정
      await worksheet.values.insertRow(1, headers);

      // 헤더 스타일 설정 (굵게, 중앙정렬)
      // GSheets API는 직접적으로 스타일을 적용할 수 없어서 별도 처리 필요
    }

    return worksheet;
  }

  /// 라이브커머스 대관 데이터 내보내기
  Future<bool> exportLiveCommerceRental(
    RentalModel rental,
    UserModel user,
    Map<String, dynamic>? documentData,
    List<EquipmentModel>? equipmentList,
  ) async {
    if (_liveCommerceSheet == null) {
      await _prepareWorksheets();
      if (_liveCommerceSheet == null) return false;
    }

    try {
      final rentalDate = DateFormatter.formatDate(rental.rentalDate);
      final dayOfWeek = DateFormatter.getDayOfWeek(rental.rentalDate);

      // 문서 데이터에서 필요한 정보 추출
      final metadata = documentData?['metadata'] as Map<String, dynamic>? ?? {};

      // 장비 목록을 문자열로 변환
      String equipmentListStr = '';
      if (equipmentList != null && equipmentList.isNotEmpty) {
        equipmentListStr = equipmentList
            .map((e) => '${e.name}(${rental.getEquipmentQuantity(e.id)}개)')
            .join(', ');
      }

      // 라이브커머스 정보 추출
      final brandName = metadata['brand_name'] as String? ?? '';
      final productName = metadata['product_name'] as String? ?? '';
      final productCount = metadata['product_count'] as int? ?? 0;
      final category = metadata['category'] as String? ?? '';
      final isSeoulSmallBusiness =
          metadata['is_seoul_small_business'] as bool? ?? false;
      final showHost = metadata['show_host'] as String? ?? '';
      final viewerCount = metadata['viewer_count'] as int? ?? 0;
      final revenue = metadata['revenue'] as int? ?? 0;
      final channel = metadata['channel'] as String? ?? '';
      final notes = rental.notes ?? '';

      // 사용자 유형 추출
      final userType = user.userType == 'business' ? '기업' : '인플루언서';

      return await _liveCommerceSheet!.values.appendRow([
        rentalDate,
        dayOfWeek,
        rental.startTime,
        '${rental.startTime}~${rental.endTime}',
        rental.studioNumber,
        userType,
        user.isCompany
            ? (user.companyInfo != null
                ? user.companyInfo!['company_name'] as String? ?? ''
                : '')
            : (user.influencerInfo != null
                ? user.influencerInfo!['activity_name'] as String? ?? ''
                : ''),
        user.isCompany && user.companyInfo != null
            ? user.companyInfo!['business_number'] as String? ?? ''
            : '',
        brandName,
        productName,
        productCount.toString(),
        category,
        isSeoulSmallBusiness ? 'Y' : 'N',
        user.displayName ?? '',
        showHost,
        viewerCount.toString(),
        revenue.toString(),
        equipmentListStr,
        channel,
        notes,
      ]);
    } catch (e) {
      Logger.error('라이브커머스 대관 내보내기 오류: $e', tag: 'GSheetsExportService');
      return false;
    }
  }

  /// 일반 대관 데이터 내보내기
  Future<bool> exportNormalRental(
    RentalModel rental,
    UserModel user,
    Map<String, dynamic>? documentData,
    List<EquipmentModel>? equipmentList,
  ) async {
    if (_normalRentalSheet == null) {
      await _prepareWorksheets();
      if (_normalRentalSheet == null) return false;
    }

    try {
      final rentalDate = DateFormatter.formatDate(rental.rentalDate);
      final dayOfWeek = DateFormatter.getDayOfWeek(rental.rentalDate);

      // 문서 데이터에서 필요한 정보 추출
      final metadata = documentData?['metadata'] as Map<String, dynamic>? ?? {};

      // 장비 목록을 문자열로 변환
      String equipmentListStr = '';
      if (equipmentList != null && equipmentList.isNotEmpty) {
        equipmentListStr = equipmentList
            .map((e) => '${e.name}(${rental.getEquipmentQuantity(e.id)}개)')
            .join(', ');
      }

      // 일반 대관 정보 추출
      final productName = metadata['purpose'] as String? ?? '';
      final category = metadata['category'] as String? ?? '';
      final notes = rental.notes ?? '';

      // 사용자 유형 추출
      final userType = user.userType == 'business' ? '기업' : '인플루언서';

      return await _normalRentalSheet!.values.appendRow([
        rentalDate,
        dayOfWeek,
        '${rental.startTime}~${rental.endTime}',
        rental.studioNumber,
        userType,
        user.isCompany
            ? (user.companyInfo != null
                ? user.companyInfo!['company_name'] as String? ?? ''
                : '')
            : (user.influencerInfo != null
                ? user.influencerInfo!['activity_name'] as String? ?? ''
                : ''),
        user.isCompany && user.companyInfo != null
            ? user.companyInfo!['business_number'] as String? ?? ''
            : '',
        productName,
        category,
        user.displayName ?? '',
        equipmentListStr,
        notes,
      ]);
    } catch (e) {
      Logger.error('일반 대관 내보내기 오류: $e', tag: 'GSheetsExportService');
      return false;
    }
  }

  /// 만족도 조사 데이터 내보내기
  Future<bool> exportSatisfactionSurvey(
    DocumentModel document,
    RentalModel rental,
    UserModel user,
  ) async {
    if (_satisfactionSurveySheet == null) {
      await _prepareWorksheets();
      if (_satisfactionSurveySheet == null) return false;
    }

    try {
      // 문서 메타데이터에서 만족도 조사 데이터 추출
      final metadata = document.metadata ?? {};

      // 기본 정보
      final rentalDate = DateFormatter.formatDate(rental.rentalDate);
      final userName =
          user.isCompany
              ? (user.companyInfo != null
                  ? user.companyInfo!['company_name'] as String? ?? ''
                  : '')
              : (user.influencerInfo != null
                  ? user.influencerInfo!['activity_name'] as String? ?? ''
                  : '');

      // 사용자 이름이 없으면 표시 이름 사용
      final displayName = userName.isEmpty ? user.displayName ?? '' : userName;

      // 만족도 점수
      final facilityScore = metadata['facility_score'] ?? 0;
      final staffScore = metadata['staff_score'] ?? 0;
      final equipmentScore = metadata['equipment_score'] ?? 0;
      final reservationScore = metadata['reservation_score'] ?? 0;
      final cleanlinessScore = metadata['cleanliness_score'] ?? 0;
      final equipmentQualityScore = metadata['equipment_quality_score'] ?? 0;

      // 기타 정보
      final purpose = metadata['studio_benefit'] ?? '-';
      final usagePath = metadata['usage_path'] ?? '-';
      final benefit = metadata['studio_benefit'] ?? '-';
      final viewers = metadata['viewers'] ?? '0';
      final revenue = metadata['revenue'] ?? '0';
      final feedback = metadata['feedback'] ?? '';

      return await _satisfactionSurveySheet!.values.appendRow([
        displayName,
        rentalDate,
        rental.studioNumber,
        purpose,
        facilityScore.toString(),
        staffScore.toString(),
        equipmentScore.toString(),
        reservationScore.toString(),
        cleanlinessScore.toString(),
        equipmentQualityScore.toString(),
        usagePath,
        benefit,
        viewers,
        revenue,
        feedback,
        '', // 후속조치내용 (빈칸으로 시작)
        'N', // 처리여부 (기본값 N)
        '', // 비고
      ]);
    } catch (e) {
      Logger.error('만족도 조사 내보내기 오류: $e', tag: 'GSheetsExportService');
      return false;
    }
  }

  /// 스프레드시트 URL 가져오기
  String? getSpreadsheetUrl() {
    if (_spreadsheetId == null) return null;
    return 'https://docs.google.com/spreadsheets/d/$_spreadsheetId/edit';
  }

  /// 특정 시트 URL 가져오기
  String? getSheetUrl(String sheetName) {
    if (_spreadsheetId == null) return null;
    return 'https://docs.google.com/spreadsheets/d/$_spreadsheetId/edit#gid=${_getGidBySheetName(sheetName)}';
  }

  /// 시트 이름으로 GID 가져오기
  int _getGidBySheetName(String sheetName) {
    if (_spreadsheet == null) return 0;

    final sheet = _spreadsheet!.worksheetByTitle(sheetName);
    if (sheet == null) return 0;

    // GSheets에서는 직접적으로 gid를 노출하지 않으므로,
    // 시트의 인덱스를 기반으로 추정 (0부터 시작)
    final worksheets = _spreadsheet!.sheets;
    final index = worksheets.indexWhere((ws) => ws.title == sheetName);

    if (index >= 0) {
      // Google Sheets의 첫 번째 시트는 일반적으로 gid=0
      // 이후 시트들은 임의의 숫자가 할당되지만, 예제로 인덱스 기반 추정
      return index;
    }

    return 0;
  }
}
