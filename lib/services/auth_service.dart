import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:s_live_document_system/utils/logger.dart';

// 개발 환경에서 이메일 인증을 건너뛰기 위한 상수
const bool kSkipEmailVerification = true;

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
    required Map<String, dynamic> userData,
  }) async {
    try {
      Logger.info('회원가입 시도: $email, 역할: $role', tag: 'AuthService');

      // 리디렉션 URL 설정 (개발 환경에 따라 다름)
      final redirectUrl =
          kSkipEmailVerification
              ? null
              : 'io.supabase.flutterquickstart://auth-callback/';

      // 사용자 데이터에 개발 환경에서만 이메일 확인 상태 추가
      final userMetadata =
          kSkipEmailVerification
              ? {'email_confirmed': true, ...userData}
              : userData;

      // Supabase 인증 서비스를 통해 회원가입
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: redirectUrl,
        data: userMetadata,
      );

      // Check if there's an error in auth signup
      if (authResponse.user == null) {
        return AuthResponse(
          error: AuthError(message: 'Failed to create user account.'),
        );
      }

      // Create profile with role in the public_users table
      try {
        // Add the role and extra userData to the public_users table
        final userId = authResponse.user!.id;
        final profile = {'user_id': userId, 'role': role, ...userData};

        await _supabase.from('public_users').insert(profile);

        return AuthResponse(
          session: authResponse.session,
          user: authResponse.user,
        );
      } catch (e) {
        // If profile creation fails, we should ideally clean up the auth user,
        // but for simplicity, we'll just return error
        Logger.error(
          'Error creating user profile',
          error: e,
          tag: 'AuthService',
        );
        return AuthResponse(
          error: AuthError(
            message: 'Account created but failed to set user role.',
          ),
        );
      }
    } on AuthException catch (e) {
      return AuthResponse(error: AuthError(message: e.message));
    } catch (e) {
      Logger.error('Unexpected signup error', error: e, tag: 'AuthService');
      return AuthResponse(
        error: AuthError(
          message: 'An unexpected error occurred during signup.',
        ),
      );
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('로그인 시도: $email', tag: 'AuthService');

      // 직접 로그인 시도 - 이메일 확인 단계 건너뛰기
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      Logger.info(
        '로그인 결과: ${response.session != null ? '성공' : '실패'}',
        tag: 'AuthService',
      );

      if (response.session == null) {
        Logger.warning(
          '세션 생성 실패. 응답: ${response.toString()}',
          tag: 'AuthService',
        );
        return AuthResponse(
          error: AuthError(message: '로그인에 실패했습니다. 아이디와 비밀번호를 확인해주세요.'),
        );
      }

      return AuthResponse(session: response.session, user: response.user);
    } on AuthException catch (e) {
      // Supabase 오류 메시지를 사용자 친화적인 한국어 메시지로 변환
      String koreanMessage = _getKoreanAuthErrorMessage(e.message);

      // 특별히 비밀번호 관련 오류 메시지 처리
      if (e.message.contains('Invalid login credentials')) {
        koreanMessage = '비밀번호가 일치하지 않습니다.';
      }

      return AuthResponse(error: AuthError(message: koreanMessage));
    } catch (e) {
      return AuthResponse(
        error: AuthError(message: 'An unexpected error occurred.'),
      );
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // 비밀번호 재설정 이메일 전송
  Future<AuthResponse> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterquickstart://reset-callback/',
      );
      return AuthResponse(message: '비밀번호 재설정 이메일이 발송되었습니다.');
    } on AuthException catch (e) {
      return AuthResponse(error: AuthError(message: e.message));
    } catch (e) {
      return AuthResponse(
        error: AuthError(message: '비밀번호 재설정 요청 중 오류가 발생했습니다.'),
      );
    }
  }

  // 비밀번호 업데이트
  Future<AuthResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return AuthResponse(user: response.user);
    } on AuthException catch (e) {
      return AuthResponse(error: AuthError(message: e.message));
    } catch (e) {
      return AuthResponse(error: AuthError(message: '비밀번호 변경 중 오류가 발생했습니다.'));
    }
  }

  // 이메일 인증 메일 재전송
  Future<AuthResponse> resendEmailVerification(String email) async {
    try {
      await _supabase.auth.resend(type: OtpType.signup, email: email);
      return AuthResponse(message: '인증 이메일이 재전송되었습니다. 메일함을 확인해주세요.');
    } on AuthException catch (e) {
      return AuthResponse(error: AuthError(message: e.message));
    } catch (e) {
      return AuthResponse(
        error: AuthError(message: '인증 이메일 재전송 중 오류가 발생했습니다.'),
      );
    }
  }

  // 현재 사용자의 이메일 인증 상태 확인
  Future<bool> isEmailVerified() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      // 사용자 메타데이터를 가져와서 이메일 인증 상태 확인
      final metadata = user.userMetadata;
      return metadata?['email_confirmed_at'] != null;
    } catch (e) {
      Logger.error('이메일 인증 상태 확인 중 오류', error: e, tag: 'AuthService');
      return false;
    }
  }

  // Supabase 영어 에러 메시지를 사용자 친화적인 한국어 메시지로 변환
  String _getKoreanAuthErrorMessage(String englishMessage) {
    // 주요 로그인 관련 오류 메시지 변환
    if (englishMessage.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    } else if (englishMessage.contains('Email not confirmed')) {
      return '이메일 인증이 완료되지 않았습니다. 이메일을 확인해주세요.';
    } else if (englishMessage.contains('Invalid email')) {
      return '유효하지 않은 이메일 주소입니다.';
    } else if (englishMessage.contains('No user found')) {
      return '등록되지 않은 사용자입니다.';
    } else if (englishMessage.contains('Too many requests')) {
      return '너무 많은 로그인 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
    } else if (englishMessage.contains('Password is too short')) {
      return '비밀번호는 최소 6자 이상이어야 합니다.';
    } else {
      // 기본 에러 메시지 (그 외 모든 경우)
      return '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
    }
  }
}

class AuthResponse {
  final Session? session;
  final User? user;
  final AuthError? error;
  final String? message; // 성공 메시지를 위한 필드 추가

  AuthResponse({this.session, this.user, this.error, this.message});

  bool get success => error == null;
  String? get errorMessage => error?.message;
  String? get successMessage => message;
}

class AuthError {
  final String message;

  AuthError({required this.message});
}
