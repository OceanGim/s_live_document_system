import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/models/rental_model.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 사용자별 대관 목록을 위한 Provider
final userRentalsProvider = FutureProvider.family<List<RentalModel>, String>((
  ref,
  userId,
) async {
  // 사용자 ID가 없으면 빈 목록 반환
  if (userId.isEmpty) {
    return [];
  }

  try {
    Logger.info('사용자 대관 목록 조회 시작: $userId', tag: 'RentalProvider');

    // 대관 테이블에서 사용자별 대관 조회
    final rentalsData = await Supabase.instance.client
        .from('rentals')
        .select()
        .eq('user_id', userId)
        .order('rental_date', ascending: false);

    // RentalModel 리스트로 변환
    final rentals =
        rentalsData.map((data) => RentalModel.fromJson(data)).toList();

    Logger.info('사용자 대관 목록 조회 완료: ${rentals.length}개', tag: 'RentalProvider');
    return rentals;
  } catch (e, stack) {
    Logger.error(
      '사용자 대관 목록 조회 실패',
      error: e,
      stackTrace: stack,
      tag: 'RentalProvider',
    );
    return [];
  }
});

/// 현재 로그인한 사용자의 대관 목록을 위한 Provider
final currentUserRentalsProvider = FutureProvider<List<RentalModel>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  final userId = authState.userId;

  if (userId == null) {
    return [];
  }

  return ref.watch(userRentalsProvider(userId).future);
});

/// 날짜별 대관 목록을 위한 Provider
final rentalsByDateProvider =
    FutureProvider.family<List<RentalModel>, DateTime>((ref, date) async {
      try {
        Logger.info('날짜별 대관 목록 조회 시작: $date', tag: 'RentalProvider');

        // 해당 날짜의 ISO 문자열 (YYYY-MM-DD)
        final dateString = date.toIso8601String().split('T')[0];

        // 대관 테이블에서 날짜별 대관 조회
        final rentalsData = await Supabase.instance.client
            .from('rentals')
            .select()
            .eq('rental_date', dateString)
            .order('start_time');

        // RentalModel 리스트로 변환
        final rentals =
            rentalsData.map((data) => RentalModel.fromJson(data)).toList();

        Logger.info(
          '날짜별 대관 목록 조회 완료: ${rentals.length}개',
          tag: 'RentalProvider',
        );
        return rentals;
      } catch (e, stack) {
        Logger.error(
          '날짜별 대관 목록 조회 실패',
          error: e,
          stackTrace: stack,
          tag: 'RentalProvider',
        );
        return [];
      }
    });

/// 스튜디오별 대관 목록을 위한 Provider
final rentalsByStudioProvider =
    FutureProvider.family<List<RentalModel>, String>((ref, studioNumber) async {
      try {
        Logger.info('스튜디오별 대관 목록 조회 시작: $studioNumber', tag: 'RentalProvider');

        // 대관 테이블에서 스튜디오별 대관 조회
        final rentalsData = await Supabase.instance.client
            .from('rentals')
            .select()
            .eq('studio_number', studioNumber)
            .order('rental_date', ascending: false)
            .order('start_time');

        // RentalModel 리스트로 변환
        final rentals =
            rentalsData.map((data) => RentalModel.fromJson(data)).toList();

        Logger.info(
          '스튜디오별 대관 목록 조회 완료: ${rentals.length}개',
          tag: 'RentalProvider',
        );
        return rentals;
      } catch (e, stack) {
        Logger.error(
          '스튜디오별 대관 목록 조회 실패',
          error: e,
          stackTrace: stack,
          tag: 'RentalProvider',
        );
        return [];
      }
    });

/// 대관 상태별 필터링을 위한 Provider
final filteredRentalsProvider =
    Provider.family<List<RentalModel>, FilterParams>((ref, params) {
      final asyncRentals = ref.watch(userRentalsProvider(params.userId));

      return asyncRentals.when(
        data: (rentals) {
          // 필터링 조건이 없으면 전체 목록 반환
          if (params.status.isEmpty && params.studioNumber.isEmpty) {
            return rentals;
          }

          // 조건에 따라 필터링
          return rentals.where((rental) {
            bool statusMatches =
                params.status.isEmpty || rental.status == params.status;
            bool studioMatches =
                params.studioNumber.isEmpty ||
                rental.studioNumber == params.studioNumber;
            return statusMatches && studioMatches;
          }).toList();
        },
        loading: () => [],
        error: (_, __) => [],
      );
    });

/// 필터링 파라미터 클래스
class FilterParams {
  final String userId;
  final String status;
  final String studioNumber;

  FilterParams({
    required this.userId,
    this.status = '',
    this.studioNumber = '',
  });
}

/// 단일 대관 정보 관리를 위한 Provider
final rentalProvider =
    StateNotifierProvider<RentalNotifier, AsyncValue<RentalModel?>>((ref) {
      return RentalNotifier();
    });

/// 대관 관리 Notifier
class RentalNotifier extends StateNotifier<AsyncValue<RentalModel?>> {
  RentalNotifier() : super(const AsyncValue.loading());

  /// 대관 정보 조회
  Future<void> fetchRental(String rentalId) async {
    state = const AsyncValue.loading();

    try {
      Logger.info('대관 정보 조회 시작: $rentalId', tag: 'RentalNotifier');

      // 대관 조회
      final rentalData =
          await Supabase.instance.client
              .from('rentals')
              .select()
              .eq('id', rentalId)
              .single();

      if (rentalData != null) {
        // RentalModel로 변환
        final rental = RentalModel.fromJson(rentalData);
        state = AsyncValue.data(rental);
        Logger.info('대관 정보 조회 완료', tag: 'RentalNotifier');
      } else {
        state = const AsyncValue.data(null);
        Logger.warning('대관을 찾을 수 없음: $rentalId', tag: 'RentalNotifier');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Logger.error(
        '대관 정보 조회 실패',
        error: e,
        stackTrace: stack,
        tag: 'RentalNotifier',
      );
    }
  }

  /// 새 대관 신청
  Future<RentalModel?> createRental({
    required String userId,
    required String studioNumber,
    required DateTime rentalDate,
    required String startTime,
    required String endTime,
    String? companyName,
    String? userName,
    String? contactPhone,
    String? purpose,
    String? notes,
    Map<String, dynamic>? equipmentRented,
  }) async {
    try {
      Logger.info('새 대관 신청 시작', tag: 'RentalNotifier');

      // 대관 시간 중복 체크
      final isTimeAvailable = await _checkTimeAvailability(
        studioNumber,
        rentalDate,
        startTime,
        endTime,
      );

      if (!isTimeAvailable) {
        Logger.warning('선택한 시간에 이미 예약이 있습니다', tag: 'RentalNotifier');
        throw Exception('선택한 시간에 이미 다른 예약이 존재합니다');
      }

      // 새 대관 데이터 준비
      final Map<String, dynamic> rentalData = {
        'user_id': userId,
        'studio_number': studioNumber,
        'rental_date': rentalDate.toIso8601String().split('T')[0],
        'start_time': startTime,
        'end_time': endTime,
        'status': 'reserved', // 초기 상태는 예약
        'company_name': companyName,
        'user_name': userName,
        'contact_phone': contactPhone,
        'purpose': purpose,
        'notes': notes,
        'equipment_rented': equipmentRented,
        'photo_uploaded': false,
        'equipment_returned': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      // 대관 생성
      final result =
          await Supabase.instance.client
              .from('rentals')
              .insert(rentalData)
              .select()
              .single();

      // RentalModel로 변환
      final rental = RentalModel.fromJson(result);
      state = AsyncValue.data(rental);

      Logger.info('새 대관 신청 완료: ${rental.id}', tag: 'RentalNotifier');
      return rental;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Logger.error(
        '새 대관 신청 실패',
        error: e,
        stackTrace: stack,
        tag: 'RentalNotifier',
      );
      return null;
    }
  }

  /// 대관 정보 업데이트
  Future<bool> updateRental(String rentalId, Map<String, dynamic> data) async {
    try {
      Logger.info('대관 정보 업데이트 시작: $rentalId', tag: 'RentalNotifier');

      // 업데이트 데이터에 수정 시간 추가
      final updateData = {
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 대관 업데이트
      await Supabase.instance.client
          .from('rentals')
          .update(updateData)
          .eq('id', rentalId);

      // 업데이트 후 대관 정보 새로고침
      await fetchRental(rentalId);

      Logger.info('대관 정보 업데이트 완료', tag: 'RentalNotifier');
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Logger.error(
        '대관 정보 업데이트 실패',
        error: e,
        stackTrace: stack,
        tag: 'RentalNotifier',
      );
      return false;
    }
  }

  /// 대관 상태 변경
  Future<bool> updateRentalStatus(String rentalId, String status) async {
    try {
      Logger.info('대관 상태 변경 시작: $rentalId -> $status', tag: 'RentalNotifier');

      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 상태가 'completed'인 경우 완료 시간도 설정
      if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      // 대관 상태 업데이트
      await Supabase.instance.client
          .from('rentals')
          .update(updateData)
          .eq('id', rentalId);

      // 업데이트 후 대관 정보 새로고침
      await fetchRental(rentalId);

      Logger.info('대관 상태 변경 완료', tag: 'RentalNotifier');
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Logger.error(
        '대관 상태 변경 실패',
        error: e,
        stackTrace: stack,
        tag: 'RentalNotifier',
      );
      return false;
    }
  }

  /// 대관 취소
  Future<bool> cancelRental(String rentalId) async {
    return updateRentalStatus(rentalId, 'cancelled');
  }

  /// 대관 시간대 가용성 체크
  Future<bool> _checkTimeAvailability(
    String studioNumber,
    DateTime rentalDate,
    String startTime,
    String endTime,
  ) async {
    try {
      final dateString = rentalDate.toIso8601String().split('T')[0];

      // 같은 날짜, 같은 스튜디오의 대관 목록 가져오기
      final existingRentals = await Supabase.instance.client
          .from('rentals')
          .select()
          .eq('studio_number', studioNumber)
          .eq('rental_date', dateString)
          .neq('status', 'cancelled') // 취소된 대관은 제외
          .order('start_time');

      // 시간 변환 (HH:MM -> 분 단위)
      final startMinutes = _timeToMinutes(startTime);
      final endMinutes = _timeToMinutes(endTime);

      // 기존 예약과 시간 겹침 확인
      for (final rental in existingRentals) {
        final existingStartMinutes = _timeToMinutes(rental['start_time']);
        final existingEndMinutes = _timeToMinutes(rental['end_time']);

        // 시간 겹침 체크
        if (!(endMinutes <= existingStartMinutes ||
            startMinutes >= existingEndMinutes)) {
          return false; // 시간 겹침
        }
      }

      return true; // 시간 사용 가능
    } catch (e, stack) {
      Logger.error(
        '대관 시간 가용성 체크 실패',
        error: e,
        stackTrace: stack,
        tag: 'RentalNotifier',
      );
      return false; // 오류 발생 시 사용 불가능으로 간주
    }
  }

  /// 시간 문자열(HH:MM)을 분 단위로 변환
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

/// 모든 스튜디오 목록을 위한 Provider
final studiosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    Logger.info('스튜디오 목록 조회 시작', tag: 'RentalProvider');

    // 스튜디오 정보 조회
    final studiosData = await Supabase.instance.client
        .from('studios')
        .select()
        .order('studio_number');

    Logger.info('스튜디오 목록 조회 완료: ${studiosData.length}개', tag: 'RentalProvider');
    return studiosData;
  } catch (e, stack) {
    Logger.error(
      '스튜디오 목록 조회 실패',
      error: e,
      stackTrace: stack,
      tag: 'RentalProvider',
    );
    return [];
  }
});
