import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/models/user_model.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 현재 로그인한 사용자 정보를 제공하는 Provider
final userInfoProvider = StateNotifierProvider<UserInfoNotifier, UserModel?>((
  ref,
) {
  final authState = ref.watch(authProvider);
  final userId = authState.userId;

  return UserInfoNotifier(ref, userId);
});

/// 사용자 정보 관리 Notifier
class UserInfoNotifier extends StateNotifier<UserModel?> {
  final Ref ref;
  final String? userId;

  UserInfoNotifier(this.ref, this.userId) : super(null) {
    if (userId != null) {
      _fetchUserInfo();
    }
  }

  /// 사용자 정보 조회
  Future<void> _fetchUserInfo() async {
    if (userId == null || !mounted) {
      return;
    }

    try {
      Logger.info('사용자 정보 조회 시작: $userId', tag: 'UserInfoNotifier');

      // 사용자 정보 테이블에서 데이터 조회
      final userData =
          await Supabase.instance.client
              .from('public_users')
              .select()
              .eq('user_id', userId!)
              .maybeSingle(); // single 대신 maybeSingle 사용하여 결과가 없는 경우 에러 방지

      if (!mounted) return; // 비동기 작업 후 마운트 상태 확인

      Logger.debug('사용자 정보 조회 결과: $userData', tag: 'UserInfoNotifier');

      // 기본 사용자 정보 가져오기
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null && userData != null) {
        // UserModel로 변환
        final userModel = UserModel(
          id: userId!,
          email: user.email ?? '',
          displayName: userData['display_name'] ?? '',
          phone: userData['phone'] ?? '',
          userType: userData['user_type'] ?? '',
          role: userData['role'] ?? 'user',
          companyName: userData['company_name'],
          isEmailConfirmed: userData['is_email_confirmed'] ?? false,
          createdAt: DateTime.parse(
            userData['created_at'] ?? DateTime.now().toIso8601String(),
          ),
          lastSignedIn:
              user.lastSignInAt != null
                  ? DateTime.parse(user.lastSignInAt!)
                  : null,
        );

        if (mounted) {
          state = userModel;
          Logger.info('사용자 정보 로드 완료', tag: 'UserInfoNotifier');
        }
      } else {
        Logger.warning('사용자 정보가 없거나 불완전합니다', tag: 'UserInfoNotifier');
        if (mounted) {
          state = null;
        }
      }
    } catch (e, stack) {
      Logger.error(
        '사용자 정보 조회 실패',
        error: e,
        stackTrace: stack,
        tag: 'UserInfoNotifier',
      );
      if (mounted) {
        state = null;
      }
    }
  }

  /// 사용자 정보 새로고침
  Future<void> refreshUserInfo() async {
    await _fetchUserInfo();
  }

  /// 사용자 정보 업데이트
  Future<bool> updateUserInfo(Map<String, dynamic> data) async {
    if (userId == null || state == null) {
      Logger.error('사용자 정보 업데이트 실패: 로그인 필요', tag: 'UserInfoNotifier');
      return false;
    }

    try {
      Logger.info('사용자 정보 업데이트 시작', tag: 'UserInfoNotifier');

      // 사용자 정보 테이블 업데이트
      await Supabase.instance.client
          .from('public_users')
          .update(data)
          .eq('user_id', userId!);

      // 업데이트 후 정보 새로고침
      await _fetchUserInfo();

      Logger.info('사용자 정보 업데이트 완료', tag: 'UserInfoNotifier');
      return true;
    } catch (e, stack) {
      Logger.error(
        '사용자 정보 업데이트 실패',
        error: e,
        stackTrace: stack,
        tag: 'UserInfoNotifier',
      );
      return false;
    }
  }

  /// 현재 사용자 프로필 이미지 URL 가져오기
  Future<String?> getUserProfileImageUrl() async {
    if (userId == null) return null;

    try {
      final String path = 'profiles/$userId/profile.jpg';

      // 파일이 존재하는지 확인
      final List<FileObject> files = await Supabase.instance.client.storage
          .from('public')
          .list(path: 'profiles/$userId');

      if (files.isNotEmpty) {
        // 파일이 존재하면 URL 생성하여 반환
        final String imageUrl = Supabase.instance.client.storage
            .from('public')
            .getPublicUrl(path);

        Logger.debug('프로필 이미지 URL: $imageUrl', tag: 'UserInfoNotifier');
        return imageUrl;
      }
    } catch (e) {
      Logger.error('프로필 이미지 URL 조회 실패', error: e, tag: 'UserInfoNotifier');
    }

    return null;
  }

  /// 사용자 프로필 이미지 업로드
  Future<bool> uploadProfileImage(List<int> imageBytes) async {
    if (userId == null) return false;

    try {
      Logger.info('프로필 이미지 업로드 시작', tag: 'UserInfoNotifier');

      final String path = 'profiles/$userId/profile.jpg';

      // 이미지 업로드
      await Supabase.instance.client.storage
          .from('public')
          .uploadBinary(path, Uint8List.fromList(imageBytes));

      Logger.info('프로필 이미지 업로드 완료', tag: 'UserInfoNotifier');
      return true;
    } catch (e, stack) {
      Logger.error(
        '프로필 이미지 업로드 실패',
        error: e,
        stackTrace: stack,
        tag: 'UserInfoNotifier',
      );
      return false;
    }
  }
}

/// 모든 사용자 목록을 조회하는 Provider (관리자용)
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final authState = ref.watch(authProvider);

  // 관리자만 접근 가능
  if (authState.userRole != 'admin') {
    return [];
  }

  try {
    Logger.info('모든 사용자 목록 조회 시작', tag: 'AllUsersProvider');

    // 사용자 정보 테이블에서 데이터 조회
    final usersData = await Supabase.instance.client
        .from('public_users')
        .select()
        .order('created_at', ascending: false);

    // UserModel 리스트로 변환
    final users =
        usersData.map((data) {
          return UserModel(
            id: data['user_id'],
            email: data['email'] ?? '',
            displayName: data['display_name'] ?? '',
            phone: data['phone'] ?? '',
            userType: data['user_type'] ?? '',
            role: data['role'] ?? 'user',
            companyName: data['company_name'],
            isEmailConfirmed: data['is_email_confirmed'] ?? false,
            createdAt: DateTime.parse(
              data['created_at'] ?? DateTime.now().toIso8601String(),
            ),
          );
        }).toList();

    Logger.info('모든 사용자 목록 조회 완료: ${users.length}명', tag: 'AllUsersProvider');
    return users;
  } catch (e, stack) {
    Logger.error(
      '사용자 목록 조회 실패',
      error: e,
      stackTrace: stack,
      tag: 'AllUsersProvider',
    );
    return [];
  }
});

/// 사용자 유형별로 필터링된 사용자 목록을 제공하는 Provider (관리자용)
final filteredUsersProvider = Provider.family<List<UserModel>, String>((
  ref,
  userType,
) {
  final asyncUsers = ref.watch(allUsersProvider);

  return asyncUsers.when(
    data: (users) {
      if (userType.isEmpty) {
        return users;
      }
      return users.where((user) => user.userType == userType).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
