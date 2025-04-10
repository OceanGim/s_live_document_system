import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/models/equipment_model.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 모든 장비 목록을 위한 Provider
final allEquipmentsProvider = FutureProvider<List<EquipmentModel>>((ref) async {
  try {
    Logger.info('모든 장비 목록 조회 시작', tag: 'EquipmentProvider');

    // 장비 테이블에서 모든 장비 조회
    final equipmentsData = await Supabase.instance.client
        .from('equipments')
        .select()
        .order('category')
        .order('name');

    // EquipmentModel 리스트로 변환
    final equipments =
        equipmentsData.map((data) => EquipmentModel.fromJson(data)).toList();

    Logger.info(
      '모든 장비 목록 조회 완료: ${equipments.length}개',
      tag: 'EquipmentProvider',
    );
    return equipments;
  } catch (e, stack) {
    Logger.error(
      '장비 목록 조회 실패',
      error: e,
      stackTrace: stack,
      tag: 'EquipmentProvider',
    );
    return [];
  }
});

/// 카테고리별 장비 목록을 위한 Provider
final equipmentsByCategoryProvider =
    FutureProvider.family<List<EquipmentModel>, String>((ref, category) async {
      try {
        Logger.info('카테고리별 장비 목록 조회 시작: $category', tag: 'EquipmentProvider');

        // 장비 테이블에서 카테고리별 장비 조회
        final equipmentsData = await Supabase.instance.client
            .from('equipments')
            .select()
            .eq('category', category)
            .order('name');

        // EquipmentModel 리스트로 변환
        final equipments =
            equipmentsData
                .map((data) => EquipmentModel.fromJson(data))
                .toList();

        Logger.info(
          '카테고리별 장비 목록 조회 완료: ${equipments.length}개',
          tag: 'EquipmentProvider',
        );
        return equipments;
      } catch (e, stack) {
        Logger.error(
          '카테고리별 장비 목록 조회 실패',
          error: e,
          stackTrace: stack,
          tag: 'EquipmentProvider',
        );
        return [];
      }
    });

/// 대여 가능한 장비 목록을 위한 Provider
final availableEquipmentsProvider = FutureProvider<List<EquipmentModel>>((
  ref,
) async {
  try {
    Logger.info('대여 가능 장비 목록 조회 시작', tag: 'EquipmentProvider');

    // 장비 테이블에서 대여 가능한 장비 조회
    final equipmentsData = await Supabase.instance.client
        .from('equipments')
        .select()
        .eq('status', 'available')
        .gt('available_quantity', 0)
        .order('category')
        .order('name');

    // EquipmentModel 리스트로 변환
    final equipments =
        equipmentsData.map((data) => EquipmentModel.fromJson(data)).toList();

    Logger.info(
      '대여 가능 장비 목록 조회 완료: ${equipments.length}개',
      tag: 'EquipmentProvider',
    );
    return equipments;
  } catch (e, stack) {
    Logger.error(
      '대여 가능 장비 목록 조회 실패',
      error: e,
      stackTrace: stack,
      tag: 'EquipmentProvider',
    );
    return [];
  }
});

/// 특정 장비 정보를 위한 Provider
final equipmentProvider = FutureProvider.family<EquipmentModel?, String>((
  ref,
  equipmentId,
) async {
  try {
    Logger.info('장비 정보 조회 시작: $equipmentId', tag: 'EquipmentProvider');

    // 장비 조회
    final equipmentData =
        await Supabase.instance.client
            .from('equipments')
            .select()
            .eq('id', equipmentId)
            .single();

    if (equipmentData == null) {
      Logger.warning('장비를 찾을 수 없음: $equipmentId', tag: 'EquipmentProvider');
      return null;
    }

    // EquipmentModel로 변환
    final equipment = EquipmentModel.fromJson(equipmentData);

    Logger.info('장비 정보 조회 완료', tag: 'EquipmentProvider');
    return equipment;
  } catch (e, stack) {
    Logger.error(
      '장비 정보 조회 실패',
      error: e,
      stackTrace: stack,
      tag: 'EquipmentProvider',
    );
    return null;
  }
});

/// 장비 카테고리 목록을 위한 Provider
final equipmentCategoriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    Logger.info('장비 카테고리 목록 조회 시작', tag: 'EquipmentProvider');

    // 장비 테이블에서 모든 카테고리 조회
    final categoriesData = await Supabase.instance.client
        .from('equipments')
        .select('category')
        .order('category');

    // 중복 제거 및 리스트 변환
    final categories =
        categoriesData
            .map((data) => data['category'] as String)
            .toSet()
            .toList();

    Logger.info(
      '장비 카테고리 목록 조회 완료: ${categories.length}개',
      tag: 'EquipmentProvider',
    );
    return categories;
  } catch (e, stack) {
    Logger.error(
      '장비 카테고리 목록 조회 실패',
      error: e,
      stackTrace: stack,
      tag: 'EquipmentProvider',
    );
    return [];
  }
});

/// 장비 관리 Notifier
class EquipmentNotifier extends StateNotifier<AsyncValue<EquipmentModel?>> {
  EquipmentNotifier() : super(const AsyncValue.loading());

  /// 장비 정보 조회
  Future<void> fetchEquipment(String equipmentId) async {
    state = const AsyncValue.loading();

    try {
      Logger.info('장비 정보 조회 시작: $equipmentId', tag: 'EquipmentNotifier');

      // 장비 조회
      final equipmentData =
          await Supabase.instance.client
              .from('equipments')
              .select()
              .eq('id', equipmentId)
              .single();

      if (equipmentData != null) {
        // EquipmentModel로 변환
        final equipment = EquipmentModel.fromJson(equipmentData);
        state = AsyncValue.data(equipment);
        Logger.info('장비 정보 조회 완료', tag: 'EquipmentNotifier');
      } else {
        state = const AsyncValue.data(null);
        Logger.warning('장비를 찾을 수 없음: $equipmentId', tag: 'EquipmentNotifier');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Logger.error(
        '장비 정보 조회 실패',
        error: e,
        stackTrace: stack,
        tag: 'EquipmentNotifier',
      );
    }
  }

  /// 장비 정보 업데이트
  Future<bool> updateEquipment(
    String equipmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      Logger.info('장비 정보 업데이트 시작: $equipmentId', tag: 'EquipmentNotifier');

      // 장비 업데이트
      await Supabase.instance.client
          .from('equipments')
          .update(data)
          .eq('id', equipmentId);

      // 업데이트 후 장비 정보 새로고침
      await fetchEquipment(equipmentId);

      Logger.info('장비 정보 업데이트 완료', tag: 'EquipmentNotifier');
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Logger.error(
        '장비 정보 업데이트 실패',
        error: e,
        stackTrace: stack,
        tag: 'EquipmentNotifier',
      );
      return false;
    }
  }

  /// 장비 수량 업데이트 (대여/반납)
  Future<bool> updateEquipmentQuantity(
    String equipmentId,
    int quantity,
    bool isRental,
  ) async {
    try {
      Logger.info(
        '장비 수량 업데이트 시작: $equipmentId (${isRental ? "대여" : "반납"}: $quantity)',
        tag: 'EquipmentNotifier',
      );

      // 현재 장비 정보 조회
      final equipmentData =
          await Supabase.instance.client
              .from('equipments')
              .select('total_quantity, available_quantity')
              .eq('id', equipmentId)
              .single();

      if (equipmentData == null) {
        Logger.warning('장비를 찾을 수 없음: $equipmentId', tag: 'EquipmentNotifier');
        return false;
      }

      final totalQuantity = equipmentData['total_quantity'] as int;
      final availableQuantity = equipmentData['available_quantity'] as int;

      // 수량 계산
      int newAvailableQuantity;
      if (isRental) {
        // 대여 시 가용 수량 감소
        newAvailableQuantity = availableQuantity - quantity;
        if (newAvailableQuantity < 0) {
          Logger.warning(
            '장비 대여 가능 수량 부족: $equipmentId, 가용: $availableQuantity, 요청: $quantity',
            tag: 'EquipmentNotifier',
          );
          return false;
        }
      } else {
        // 반납 시 가용 수량 증가
        newAvailableQuantity = availableQuantity + quantity;
        if (newAvailableQuantity > totalQuantity) {
          Logger.warning(
            '장비 반납 수량 초과: $equipmentId, 전체: $totalQuantity, 반납 후: $newAvailableQuantity',
            tag: 'EquipmentNotifier',
          );
          return false;
        }
      }

      // 상태 업데이트
      final String status = newAvailableQuantity > 0 ? 'available' : 'rented';

      // 장비 업데이트
      await Supabase.instance.client
          .from('equipments')
          .update({
            'available_quantity': newAvailableQuantity,
            'status': status,
          })
          .eq('id', equipmentId);

      // 업데이트 후 장비 정보 새로고침
      await fetchEquipment(equipmentId);

      Logger.info(
        '장비 수량 업데이트 완료: $equipmentId, 새 가용 수량: $newAvailableQuantity',
        tag: 'EquipmentNotifier',
      );
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Logger.error(
        '장비 수량 업데이트 실패',
        error: e,
        stackTrace: stack,
        tag: 'EquipmentNotifier',
      );
      return false;
    }
  }
}

/// 장비 관리를 위한 Provider
final equipmentNotifierProvider =
    StateNotifierProvider<EquipmentNotifier, AsyncValue<EquipmentModel?>>(
      (ref) => EquipmentNotifier(),
    );
