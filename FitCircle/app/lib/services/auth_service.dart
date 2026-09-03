// lib/services/auth_service.dart
// FitCircle — Authentication service wrapping Supabase Auth
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final _client = SupabaseConfig.client;

  // ── Current session ────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Sign Up ───────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  // ── Sign In ───────────────────────────────────────────
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Sign Out ──────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Reset Password ────────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ── Update Password ───────────────────────────────────
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
