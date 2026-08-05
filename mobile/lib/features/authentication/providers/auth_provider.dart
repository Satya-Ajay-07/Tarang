import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/exceptions/app_exceptions.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/core/repositories/authentication_repository.dart';

enum AuthStatus {
  initial,
  checking,
  authenticated,
  unverified,
  deactivated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? unverifiedEmail;
  final double? deactivationDaysRemaining;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.unverifiedEmail,
    this.deactivationDaysRemaining,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        errorMessage = null,
        unverifiedEmail = null,
        deactivationDaysRemaining = null;

  const AuthState.checking()
      : status = AuthStatus.checking,
        user = null,
        errorMessage = null,
        unverifiedEmail = null,
        deactivationDaysRemaining = null;

  const AuthState.authenticated(UserModel user)
      : status = AuthStatus.authenticated,
        this.user = user,
        errorMessage = null,
        unverifiedEmail = null,
        deactivationDaysRemaining = null;

  const AuthState.unverified(String email)
      : status = AuthStatus.unverified,
        user = null,
        errorMessage = null,
        unverifiedEmail = email,
        deactivationDaysRemaining = null;

  const AuthState.deactivated(String message, double? daysRemaining)
      : status = AuthStatus.deactivated,
        user = null,
        errorMessage = message,
        unverifiedEmail = null,
        deactivationDaysRemaining = daysRemaining;

  const AuthState.error(String message)
      : status = AuthStatus.error,
        user = null,
        errorMessage = message,
        unverifiedEmail = null,
        deactivationDaysRemaining = null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthenticationRepository _authRepository;
  final SecureStorageService _secureStorage;

  AuthNotifier(this._authRepository, this._secureStorage)
      : super(const AuthState.initial()) {
    checkAuthentication();
  }

  Future<void> checkAuthentication() async {
    state = const AuthState.checking();
    try {
      final accessToken = await _secureStorage.getAccessToken();
      final refreshToken = await _secureStorage.getRefreshToken();

      if (accessToken != null && refreshToken != null) {
        // Fetch current active user profile
        final user = await _authRepository.getMe();
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.initial();
      }
    } on EmailNotVerifiedException {
      state = const AuthState.unverified('');
    } on AccountDeactivatedException catch (e) {
      state = AuthState.deactivated(e.message, e.daysRemaining);
    } on Exception {
      // Clear invalid credentials to avoid loops
      await _secureStorage.deleteAccessToken();
      await _secureStorage.deleteRefreshToken();
      state = const AuthState.initial();
    }
  }

  Future<void> checkSession() async {
    await checkAuthentication();
  }

  Future<void> login(String usernameOrEmail, String password, bool rememberMe) async {
    state = const AuthState.checking();
    try {
      final token = await _authRepository.login(usernameOrEmail, password);
      
      await _secureStorage.saveAccessToken(token.accessToken);
      await _secureStorage.saveRefreshToken(token.refreshToken);
      await _secureStorage.saveRememberMe(rememberMe);

      if (rememberMe) {
        await _secureStorage.saveCredentials(usernameOrEmail, password);
      } else {
        await _secureStorage.clearCredentials();
      }

      final user = await _authRepository.getMe();
      state = AuthState.authenticated(user);
    } on EmailNotVerifiedException {
      state = AuthState.unverified(usernameOrEmail.contains('@') ? usernameOrEmail : '');
    } on AccountDeactivatedException catch (e) {
      state = AuthState.deactivated(e.message, e.daysRemaining);
    } on AppException catch (e) {
      state = AuthState.error(e.message);
    } catch (_) {
      state = AuthState.error('An unexpected error occurred during login.');
    }
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
    String? country,
    String? phoneNumber,
  }) async {
    state = const AuthState.checking();
    try {
      final response = await _authRepository.register(
        email: email,
        username: username,
        password: password,
        fullName: fullName,
        country: country,
        phoneNumber: phoneNumber,
      );

      if (response.success) {
        state = AuthState.unverified(email);
      } else {
        state = AuthState.error(response.warning ?? 'Registration failed.');
      }
    } on AppException catch (e) {
      state = AuthState.error(e.message);
    } catch (e) {
      state = AuthState.error('An unexpected error occurred during registration.');
    }
  }

  Future<void> logout() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    state = const AuthState.checking();
    try {
      await _authRepository.logout(refreshToken);
    } finally {
      await _secureStorage.clearAll();
      state = const AuthState.initial();
    }
  }

  void setUnverifiedEmail(String email) {
    state = AuthState.unverified(email);
  }

  void clearError() {
    if (state.status == AuthStatus.error || state.status == AuthStatus.deactivated) {
      state = const AuthState.initial();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthNotifier(authRepo, secureStorage);
});
