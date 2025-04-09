import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 프로젝트 정보 상수
const String PROJECT_ID = 'jdtvghbafmwguwbbujxx';
const String PROJECT_NAME = 's-live_document_system';
const String ORGANIZATION_ID = 'usilfkzskphrjggycktd';

/// Supabase MCP를 통해 데이터베이스 작업을 처리하는 핸들러 클래스
class SupabaseMcpHandler {
  /// Supabase 초기화 여부 확인
  static bool isSupabaseInitialized() {
    try {
      final _ = Supabase.instance;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 사전 정의된 테이블 목록
  static final List<String> predefinedTables = [
    'public_users',
    'rental_requests',
    'equipment_rentals',
    'survey_responses',
    'rental_photos',
    'user_signatures',
    'user_privacy_agreements',
    'portrait_rights_agreements',
    'facility_agreements',
    'external_participants',
    'external_portrait_agreements',
    'equipment_items',
    'broadcast_reports',
    'broadcast_infos',
    'broadcast_stats',
    'broadcast_channels',
    'studio_usage_stats',
    'equipment_usage_stats',
  ];

  /// 테이블 목록 조회 (하드코딩된 테이블 목록 반환)
  static Future<List<String>> listAllTables() async {
    try {
      if (!isSupabaseInitialized()) {
        Logger.warning('Supabase가 초기화되지 않았습니다', tag: 'SupabaseMcpHandler');
        return [];
      }

      Logger.info('테이블 목록 조회 (미리 정의된 목록 사용)', tag: 'SupabaseMcpHandler');
      return predefinedTables;
    } catch (e) {
      Logger.error('테이블 목록 조회 실패', error: e, tag: 'SupabaseMcpHandler');
      return [];
    }
  }

  /// 특정 테이블의 컬럼 정보 조회 (직접 API 쿼리)
  static Future<List<Map<String, dynamic>>> getTableColumns(
    String tableName,
  ) async {
    try {
      if (!isSupabaseInitialized()) {
        Logger.warning('Supabase가 초기화되지 않았습니다', tag: 'SupabaseMcpHandler');
        return [];
      }

      Logger.info('테이블 $tableName의 컬럼 정보 조회', tag: 'SupabaseMcpHandler');

      // 샘플 데이터 한 개 가져와서 키값 추출
      final data =
          await Supabase.instance.client
              .from(tableName)
              .select()
              .limit(1)
              .maybeSingle();

      if (data == null) {
        return [];
      }

      // 키-값 쌍을 컬럼 정보로 변환
      final columns =
          data.keys.map((key) {
            final value = data[key];
            String dataType = 'unknown';

            if (value is int) {
              dataType = 'integer';
            } else if (value is double) {
              dataType = 'double';
            } else if (value is String) {
              dataType = 'text';
            } else if (value is bool) {
              dataType = 'boolean';
            } else if (value is Map) {
              dataType = 'json';
            } else if (value is List) {
              dataType = 'array';
            } else if (value == null) {
              dataType = 'nullable';
            }

            return {
              'column_name': key,
              'data_type': dataType,
              'is_nullable': value == null ? 'YES' : 'NO',
            };
          }).toList();

      Logger.info('컬럼 정보 추출 성공: ${columns.length}개', tag: 'SupabaseMcpHandler');
      return columns;
    } catch (e) {
      Logger.error('컬럼 정보 조회 실패', error: e, tag: 'SupabaseMcpHandler');
      return [];
    }
  }

  /// 특정 테이블의 데이터 조회 (직접 API 쿼리)
  static Future<List<Map<String, dynamic>>> getTableData(
    String tableName, {
    String? columnFilter,
    String? whereClause,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      if (!isSupabaseInitialized()) {
        Logger.warning('Supabase가 초기화되지 않았습니다', tag: 'SupabaseMcpHandler');
        return [];
      }

      Logger.info('테이블 $tableName 데이터 조회', tag: 'SupabaseMcpHandler');

      // 결과 반환
      final data = await Supabase.instance.client
          .from(tableName)
          .select(columnFilter ?? '*')
          .range(offset, offset + limit - 1);

      if (data == null) {
        return [];
      }

      // List<dynamic>을 List<Map<String, dynamic>>으로 변환
      final dataList =
          (data as List).map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else {
              return item as Map<String, dynamic>;
            }
          }).toList();

      Logger.info('데이터 조회 성공: ${dataList.length}개', tag: 'SupabaseMcpHandler');
      return dataList;
    } catch (e) {
      Logger.error('데이터 조회 실패', error: e, tag: 'SupabaseMcpHandler');
      return [];
    }
  }

  /// 데이터 삽입
  static Future<bool> insertData(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    try {
      if (!isSupabaseInitialized()) {
        Logger.warning('Supabase가 초기화되지 않았습니다', tag: 'SupabaseMcpHandler');
        return false;
      }

      Logger.info('테이블 $tableName에 데이터 삽입', tag: 'SupabaseMcpHandler');

      final result =
          await Supabase.instance.client.from(tableName).insert(data).select();

      Logger.info('데이터 삽입 성공', tag: 'SupabaseMcpHandler');
      return true;
    } catch (e) {
      Logger.error('데이터 삽입 실패', error: e, tag: 'SupabaseMcpHandler');
      return false;
    }
  }

  /// 데이터 업데이트
  static Future<bool> updateData(
    String tableName,
    Map<String, dynamic> data,
    String matchColumn,
    dynamic matchValue,
  ) async {
    try {
      if (!isSupabaseInitialized()) {
        Logger.warning('Supabase가 초기화되지 않았습니다', tag: 'SupabaseMcpHandler');
        return false;
      }

      Logger.info('테이블 $tableName의 데이터 업데이트', tag: 'SupabaseMcpHandler');

      final result =
          await Supabase.instance.client
              .from(tableName)
              .update(data)
              .eq(matchColumn, matchValue)
              .select();

      Logger.info('데이터 업데이트 성공', tag: 'SupabaseMcpHandler');
      return true;
    } catch (e) {
      Logger.error('데이터 업데이트 실패', error: e, tag: 'SupabaseMcpHandler');
      return false;
    }
  }

  /// 데이터 삭제
  static Future<bool> deleteData(
    String tableName,
    String matchColumn,
    dynamic matchValue,
  ) async {
    try {
      if (!isSupabaseInitialized()) {
        Logger.warning('Supabase가 초기화되지 않았습니다', tag: 'SupabaseMcpHandler');
        return false;
      }

      Logger.info('테이블 $tableName에서 데이터 삭제', tag: 'SupabaseMcpHandler');

      final result = await Supabase.instance.client
          .from(tableName)
          .delete()
          .eq(matchColumn, matchValue);

      Logger.info('데이터 삭제 성공', tag: 'SupabaseMcpHandler');
      return true;
    } catch (e) {
      Logger.error('데이터 삭제 실패', error: e, tag: 'SupabaseMcpHandler');
      return false;
    }
  }
}

/// Supabase MCP 관련 Provider
final supabaseTablesProvider = FutureProvider<List<String>>((ref) async {
  return await SupabaseMcpHandler.listAllTables();
});

/// 특정 테이블의 컬럼 정보를 제공하는 Provider 생성 함수
FutureProvider<List<Map<String, dynamic>>> tableColumnsProvider(
  String tableName,
) {
  return FutureProvider<List<Map<String, dynamic>>>((ref) async {
    return await SupabaseMcpHandler.getTableColumns(tableName);
  });
}

/// 특정 테이블의 데이터를 제공하는 Provider 생성 함수
FutureProvider<List<Map<String, dynamic>>> tableDataProvider(
  String tableName, {
  String? columnFilter,
  String? whereClause,
  int limit = 100,
  int offset = 0,
}) {
  return FutureProvider<List<Map<String, dynamic>>>((ref) async {
    return await SupabaseMcpHandler.getTableData(
      tableName,
      columnFilter: columnFilter,
      whereClause: whereClause,
      limit: limit,
      offset: offset,
    );
  });
}
