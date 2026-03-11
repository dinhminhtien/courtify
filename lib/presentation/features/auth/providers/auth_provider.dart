import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:courtify/core/database/supabase_config.dart';

// Represents the state of authentication
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final User? user;
  final int? userId;
  final String? role;
  
  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.userId,
    this.role,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    User? user,
    int? userId,
    String? role,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
      userId: userId ?? this.userId,
      role: role ?? this.role,
    );
  }
}

// Modern Riverpod Notifier to manage Authentication logic
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final client = SupabaseConfig.client;
    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      _fetchUserData(currentUser.email!);
    }
    return AuthState(user: currentUser);
  }

  SupabaseClient get _client => SupabaseConfig.client;

  Future<void> _fetchUserData(String email) async {
    try {
      final userData = await _client
          .from('users')
          .select('user_id, role')
          .eq('email', email)
          .single();
      state = state.copyWith(
        userId: userData['user_id'] as int,
        role: userData['role'] as String,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: "Failed to fetch user profiles: $e");
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final userData = await _client
          .from('users')
          .select('user_id, role')
          .eq('email', email)
          .single();

      state = state.copyWith(
        isLoading: false, 
        user: response.user,
        userId: userData['user_id'] as int,
        role: userData['role'] as String,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _client.auth.signOut();
    state = state.copyWith(isLoading: false, user: null, userId: null, role: null);
  }
}

// Provider to be consumed by the UI
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
