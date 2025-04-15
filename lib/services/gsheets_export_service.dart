import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
      // flutter_dotenv를 사용하여 .env 파일에서 값 로드
      final credentials = const String.fromEnvironment('GOOGLE_SHEETS_CREDENTIALS');
      if (credentials.isNotEmpty) {
        return credentials;
      }
      
      // 환경 변수에서 값을 가져오지 못한 경우 flutter_dotenv 사용
      final dotEnvCredentials = dotenv.env['GOOGLE_SHEETS_CREDENTIALS'];
      if (dotEnvCredentials != null && dotEnvCredentials.isNotEmpty) {
        return dotEnvCredentials;
      }
      
      throw Exception('Google Sheets 자격 증명을 찾을 수 없습니다');
    } catch (e) {
      Logger.error('Google Sheets 자격 증명 로드 오류: $e', tag: 'GSheetsExportService');
      throw Exception('Google Sheets 자격 증명을 로드할 수 없습니다: $e');
    }
  }

  /// 스프레드시트 ID 로드
  Future<String?> _loadSpreadsheetId() async {
    try {
      // 컴파일 타임 환경 변수 확인
      final spreadsheetId = const String.fromEnvironment('GOOGLE_SHEETS_ID');
      if (spreadsheetId.isNotEmpty) {
        return spreadsheetId;
      }
      
      // .env 파일에서 로드
      final dotEnvSpreadsheetId = dotenv.env['GOOGLE_SHEETS_ID'];
      if (dotEnvSpreadsheetId != null && dotEnvSpreadsheetId.isNotEmpty) {
        return dotEnvSpreadsheetId;
      }
      
      Logger.error('스프레드시트 ID를 찾을 수 없습니다', tag: 'GSheetsExportService');
      return null;
    } catch (e) {
      Logger.error('스프레드시트 ID 로드 오류: $e', tag: 'GSheetsExportService');
      return null;
    }
  }