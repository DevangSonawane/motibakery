import '../models/app_user.dart';

class AuthService {
  Future<AppUser> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (password.trim().length < 4) {
      throw const AuthException('Invalid email or password');
    }

    final normalized = email.trim().toLowerCase();
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
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}
