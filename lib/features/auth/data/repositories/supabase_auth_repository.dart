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
        // Use the current page origin as redirect so it works in both
        // local dev (http://127.0.0.1:5000) and production.
        final redirectTo = Uri.base.origin;
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectTo,
        );
        // signInWithOAuth on web redirects the browser; return value is
        // irrelevant — the session is picked up when the page reloads.
        return true;
      } else {
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'https://kkbregpvyitljqjcjesa.supabase.co/auth/v1/callback',
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

  @override
  Future<void> updateProfile({String? fullName, String? phone}) async {
    final user = currentUser;
    if (user == null) return;
    try {
      final Map<String, dynamic> data = {};
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;

      if (data.isNotEmpty) {
        await _client.from('users').update(data).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }
}
