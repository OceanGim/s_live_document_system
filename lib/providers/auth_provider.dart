import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Define a provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final supabase = Supabase.instance.client;
  return AuthService(supabase);
});

// Define a state provider to manage the authentication state
final authProvider = StateNotifierProvider<AuthProvider, AuthState>((ref) {
  return AuthProvider(ref);
});

// Define the AuthState
class AuthState {
  final bool isLoggedIn;
  final String? userId;
  final String? userRole; // 'admin' or 'user'
  final String? errorMessage;

  AuthState({
    this.isLoggedIn = false,
    this.userId,
    this.userRole,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userId,
    String? userRole,
    String? errorMessage,
    bool clearErrorMessage = false, // Added to explicitly clear error
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// Define the AuthProvider
class AuthProvider extends StateNotifier<AuthState> {
  final Ref ref;

  AuthProvider(this.ref) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await _setSession(session);
    } else {
      state = state.copyWith(
        isLoggedIn: false,
        userId: null,
        userRole: null,
        clearErrorMessage: true,
      );
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      final session = event.session;
      if (event.event == AuthChangeEvent.signedIn && session != null) {
        await _setSession(session);
      } else if (event.event == AuthChangeEvent.signedOut) {
        state = state.copyWith(
          isLoggedIn: false,
          userId: null,
          userRole: null,
          clearErrorMessage: true,
        );
      } else if (event.event == AuthChangeEvent.userUpdated &&
          session != null) {
        // Re-fetch role if user data might have changed
        await _getUserRole();
      }
    });
  }

  Future<void> _setSession(Session session) async {
    state = state.copyWith(
      isLoggedIn: true,
      userId: session.user.id,
      clearErrorMessage: true,
    );
    await _getUserRole();
  }

  Future<void> _getUserRole() async {
    final userId = state.userId;
    if (userId == null) {
      state = state.copyWith(
        userRole: null,
        errorMessage: 'User ID not available.',
      );
      return;
    }

    try {
      // Fetch user role from Supabase using the new syntax
      final result =
          await Supabase.instance.client
              .from('public_users') // Ensure this table name is correct
              .select('role')
              .eq('user_id', userId)
              .maybeSingle(); // Use maybeSingle() as user might not have a profile entry yet

      if (result == null) {
        // Handle case where user profile or role is not found
        state = state.copyWith(
          userRole: null,
          // Consider if this is an error or just a state (e.g., profile pending)
          // errorMessage: 'User profile or role not found.',
          clearErrorMessage:
              true, // Clear previous errors if profile is just missing
        );
      } else {
        final role = result['role'] as String?;
        state = state.copyWith(userRole: role, clearErrorMessage: true);
      }
    } on PostgrestException catch (e) {
      // Handle specific Postgrest errors (e.g., RLS issues, network problems)
      print('Error fetching user role: ${e.message}');
      state = state.copyWith(
        userRole: null,
        errorMessage: 'Failed to fetch role: ${e.message}',
      );
    } catch (e) {
      // Handle other potential errors
      print('Unexpected error fetching user role: $e');
      state = state.copyWith(
        userRole: null,
        errorMessage: 'An unexpected error occurred while fetching user role.',
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final authService = ref.read(authServiceProvider);
    // Clear previous error message before attempting sign in
    state = state.copyWith(clearErrorMessage: true);
    final response = await authService.signIn(email: email, password: password);

    if (!response.success) {
      // The AuthService should ideally handle setting the session via onAuthStateChange
      // We just need to update the error message here if sign-in fails
      state = state.copyWith(errorMessage: response.message);
    }
    // _getUserRole will be called by the onAuthStateChange listener if sign-in is successful
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String role, // Assuming role is passed during signup
    required Map<String, dynamic>
    userData, // Additional user data for public_users
  }) async {
    final authService = ref.read(authServiceProvider);
    state = state.copyWith(clearErrorMessage: true);
    final response = await authService.signUp(
      email: email,
      password: password,
      role: role,
      userData: userData,
    );

    if (!response.success) {
      state = state.copyWith(errorMessage: response.message);
    }
    // Session handling and role fetching will be managed by onAuthStateChange
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    state = state.copyWith(clearErrorMessage: true);
    try {
      await authService.signOut();
      // State update (isLoggedIn=false, etc.) is handled by onAuthStateChange listener
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error signing out: $e');
    }
  }
}
