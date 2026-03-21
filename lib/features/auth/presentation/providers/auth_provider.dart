import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../../courts/presentation/providers/courts_provider.dart';
import '../../../booking/presentation/providers/bookings_provider.dart';
import '../../../payment/presentation/providers/payment_provider.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

// ─── Auth State ───────────────────────────────────────────────────────────────

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    UserEntity? user,
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
  late final AuthRepository _authRepository;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    Future.microtask(() => _init());
    return const AuthState(isLoading: true);
  }

  Future<void> _init() async {
    try {
      final user = await _authRepository.getCurrentUserProfile();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      if (response.user != null) {
        final profile = await _authRepository.getCurrentUserProfile();
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
      await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      final profile = await _authRepository.getCurrentUserProfile();
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
      final success = await _authRepository.signInWithGoogle();
      if (success) {
        final profile = await _authRepository.getCurrentUserProfile();
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
    await _authRepository.signOut();
    
    // Set state to null FIRST to signal all UI listeners
    state = const AuthState(user: null);
    
    // Defer invalidation of other providers to the next microtask 
    // to avoid circular dependency issues while Riverpod is rebuilding.
    // We don't need to invalidate ownerDashboardProvider because it already watches 
    // currentUserProvider and will rebuild automatically.
    Future.microtask(() {
      if (ref.mounted) {
        ref.invalidate(courtsProvider);
        ref.invalidate(bookingsProvider);
        ref.invalidate(paymentProvider);
      }
    });
  }

  Future<void> refreshProfile() async {
    try {
      final profile = await _authRepository.getCurrentUserProfile();
      state = state.copyWith(user: profile);
    } catch (e) {
      debugPrint('Refresh profile error: $e');
    }
  }

  bool get isLoggedIn => _authRepository.isLoggedIn;

  Future<bool> updateProfile({String? fullName, String? phone}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.updateProfile(fullName: fullName, phone: phone);
      final profile = await _authRepository.getCurrentUserProfile();
      state = state.copyWith(user: profile, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});
