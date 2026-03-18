import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/config/supabase_config.dart';

// ─── Auth State ───────────────────────────────────────────────────────────────

class AuthState {
  final CourtifyUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    CourtifyUser? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  final AuthService _authService = AuthService();

  @override
  AuthState build() {
    Future.microtask(() => _init());
    return const AuthState(isLoading: true);
  }

  Future<void> _init() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (response.user != null) {
        final profile = await _authService.getCurrentUserProfile();
        state = state.copyWith(user: profile, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      final profile = await _authService.getCurrentUserProfile();
      state = state.copyWith(user: profile, isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _authService.signInWithGoogle();
      if (success) {
        final profile = await _authService.getCurrentUserProfile();
        state = state.copyWith(user: profile, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState(user: null);
  }

  Future<void> refreshProfile() async {
    try {
      final profile = await _authService.getCurrentUserProfile();
      state = state.copyWith(user: profile);
    } catch (e) {
      debugPrint('Refresh profile error: $e');
    }
  }

  bool get isLoggedIn => _authService.isLoggedIn;
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

final currentUserProvider = Provider<CourtifyUser?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});
