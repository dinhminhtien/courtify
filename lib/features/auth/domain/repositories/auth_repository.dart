import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  User? get currentUser;
  bool get isLoggedIn;
  Stream<AuthState> get authStateChanges;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  Future<bool> signInWithGoogle();

  Future<void> signOut();

  Future<UserEntity?> getCurrentUserProfile();

  Future<void> updateProfile({String? fullName, String? phone});
}
