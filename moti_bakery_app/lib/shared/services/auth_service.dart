import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import 'supabase_bootstrap.dart';

class AuthService {
  Future<AppUser> login({required String email, required String password}) async {
    final normalized = email.trim().toLowerCase();

    if (SupabaseBootstrap.result.status == SupabaseBootstrapStatus.connected) {
      return _loginViaSupabase(email: normalized, password: password);
    }
    if (SupabaseBootstrap.result.status == SupabaseBootstrapStatus.failed) {
      throw AuthException(
        'Supabase connection failed. ${SupabaseBootstrap.result.message ?? ''}'.trim(),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (password.trim().length < 4) {
      throw const AuthException('Invalid email or password');
    }

    if (normalized.contains('counter')) {
      return AppUser(
        id: 'usr-counter-01',
        email: normalized,
        role: UserRole.counter,
        displayName: 'Counter Staff',
      );
    }
    if (normalized.contains('cake')) {
      return AppUser(
        id: 'usr-cakeroom-01',
        email: normalized,
        role: UserRole.cakeRoom,
        displayName: 'Cake Room Staff',
      );
    }

    throw const AuthException(
      'Use an email containing "counter" or "cake" for demo login.',
    );
  }

  Future<void> logout() async {
    if (SupabaseBootstrap.result.status == SupabaseBootstrapStatus.connected) {
      await Supabase.instance.client.auth.signOut();
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<AppUser> _loginViaSupabase({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final authUser = authResponse.user;
      if (authUser == null) {
        throw const AuthException('Invalid email or password');
      }

      final data = await Supabase.instance.client
          .from('users')
          .select('uid, full_name, gmail, role')
          .eq('uid', authUser.id)
          .maybeSingle();

      final role = _resolveRoleFromProfileOrEmail(
        roleValue: data is Map<String, dynamic> ? data['role']?.toString() : null,
        email: email,
      );
      final displayName = (data is Map<String, dynamic> &&
              (data['full_name']?.toString().trim().isNotEmpty ?? false))
          ? data['full_name'].toString().trim()
          : email.split('@').first;
      return AppUser(
        id: authUser.id,
        email: authUser.email ?? email,
        role: role,
        displayName: displayName,
      );
    } on AuthException {
      rethrow;
    } on AuthApiException catch (error) {
      final message = error.message.trim();
      if (message.isEmpty) {
        throw const AuthException('Unable to login. Please verify your credentials.');
      }
      throw AuthException(message);
    } on PostgrestException catch (error) {
      throw AuthException(error.message);
    } catch (_) {
      throw const AuthException('Unable to login. Please try again.');
    }
  }

  UserRole _mapRole(String? roleValue) {
    switch (roleValue?.toLowerCase()) {
      case 'counter':
        return UserRole.counter;
      case 'cake_room':
        return UserRole.cakeRoom;
      default:
        throw const AuthException(
          'You do not have access to this app role. Contact admin.',
        );
    }
  }

  UserRole _resolveRoleFromProfileOrEmail({
    required String? roleValue,
    required String email,
  }) {
    try {
      return _mapRole(roleValue);
    } on AuthException {
      final normalized = email.trim().toLowerCase();
      if (normalized == 'aniketjha@gmail.com' || normalized.contains('counter')) {
        return UserRole.counter;
      }
      if (normalized.contains('cake')) {
        return UserRole.cakeRoom;
      }
      rethrow;
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}
