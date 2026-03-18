import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/api/supabase_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client = SupabaseClientManager.instance.client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  bool get isLoggedIn => currentUser != null;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone, 'role': 'customer'},
    );
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'https://courtify-fbpxu80.public.builtwithrocket.new',
        );
        return true;
      } else {
        // Native Google Sign-In
        const webClientId = String.fromEnvironment(
          'GOOGLE_WEB_CLIENT_ID',
          defaultValue: '',
        );
        if (webClientId.isEmpty) return false;

        // For native, use signInWithOAuth with deep link
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.courtify://login-callback',
        );
        return true;
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }
}
