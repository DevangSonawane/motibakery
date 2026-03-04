import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});

  final AppUser? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({AppUser? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthController extends ChangeNotifier {
  AuthController(this._authService);

  final AuthService _authService;
  AuthState _state = const AuthState();

  AuthState get state => _state;

  Future<void> login({required String email, required String password}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final user = await _authService.login(email: email, password: password);
      _state = AuthState(user: user, isLoading: false, error: null);
    } on AuthException catch (e) {
      _state = AuthState(user: null, isLoading: false, error: e.message);
    } catch (_) {
      _state = const AuthState(error: 'Unable to login. Please try again.');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    await _authService.logout();
    _state = const AuthState();
    notifyListeners();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});
