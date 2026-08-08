import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/app_router.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/core/repositories/authentication_repository.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/models/token_model.dart';
import 'package:mobile/core/models/register_response_model.dart';
import 'package:mobile/core/exceptions/app_exceptions.dart';
import 'package:go_router/go_router.dart';

// Fake Secure Storage
class FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveAccessToken(String token) async =>
      _data['accessToken'] = token;

  @override
  Future<String?> getAccessToken() async => _data['accessToken'];

  @override
  Future<void> deleteAccessToken() async => _data.remove('accessToken');

  @override
  Future<void> saveRefreshToken(String token) async =>
      _data['refreshToken'] = token;

  @override
  Future<String?> getRefreshToken() async => _data['refreshToken'];

  @override
  Future<void> deleteRefreshToken() async => _data.remove('refreshToken');

  @override
  Future<void> saveRememberMe(bool remember) async =>
      _data['rememberMe'] = remember.toString();

  @override
  Future<bool> getRememberMe() async => _data['rememberMe'] == 'true';

  @override
  Future<void> saveCredentials(String usernameOrEmail, String password) async {}

  @override
  Future<Map<String, String?>> getCredentials() async => {};

  @override
  Future<void> clearCredentials() async {}

  @override
  Future<void> clearAll() async => _data.clear();

  @override
  Future<void> saveThemePreference(String theme) async {}

  @override
  Future<String?> getThemePreference() async => null;
}

// Fake Auth Repository
class FakeAuthenticationRepository implements AuthenticationRepository {
  UserModel? mockUser;
  bool shouldThrowEmailNotVerified = false;
  bool shouldThrowDeactivated = false;
  bool shouldThrowGenericException = false;
  bool loginShouldFail = false;
  bool registerShouldFail = false;

  @override
  Future<UserModel> getMe() async {
    if (shouldThrowEmailNotVerified) {
      throw EmailNotVerifiedException('Email not verified');
    }
    if (shouldThrowDeactivated) {
      throw AccountDeactivatedException('Deactivated', 10.0);
    }
    if (shouldThrowGenericException) {
      throw Exception('Generic error');
    }
    return mockUser ??
        UserModel(
          id: '1',
          username: 'testuser',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          role: 'user',
        );
  }

  @override
  Future<TokenModel> login(String usernameOrEmail, String password) async {
    if (loginShouldFail) {
      throw UnauthorizedException('Invalid credentials');
    }
    return const TokenModel(
      accessToken: 'mock_access',
      refreshToken: 'mock_refresh',
      tokenType: 'bearer',
    );
  }

  @override
  Future<RegisterResponseModel> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
    String? country,
    String? phoneNumber,
  }) async {
    if (registerShouldFail) {
      throw BadRequestException('Registration failed');
    }
    return RegisterResponseModel(
      success: true,
      user: UserModel(
        id: '2',
        username: username,
        email: email,
        createdAt: DateTime.now(),
        role: 'user',
      ),
    );
  }

  @override
  Future<bool> verifyEmail(String token) async {
    return token == 'valid_token';
  }

  @override
  Future<bool> resendVerification(String email) async {
    return email.isNotEmpty;
  }

  @override
  Future<bool> forgotPassword(String email) async {
    return email.isNotEmpty;
  }

  @override
  Future<bool> resetPassword(String token, String newPassword) async {
    return token == 'valid_token';
  }

  @override
  Future<void> logout(String? refreshToken) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGoRouterState implements GoRouterState {
  @override
  final Uri uri;

  MockGoRouterState(String path) : uri = Uri.parse(path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSecureStorageService fakeSecureStorage;
  late FakeAuthenticationRepository fakeAuthRepository;
  late ProviderContainer container;

  setUp(() {
    fakeSecureStorage = FakeSecureStorageService();
    fakeAuthRepository = FakeAuthenticationRepository();
    container = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(fakeSecureStorage),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Auth State and Redirect Tests', () {
    test(
        '1. Launching the app with no stored tokens transitions to initial -> redirects to /login',
        () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.checkAuthentication();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.initial);

      final helper = container.read(appRouterHelperProvider);
      final redirectPath =
          helper.redirect(FakeBuildContext(), MockGoRouterState('/splash'));
      expect(redirectPath, '/login');
    });

    test(
        '2. Launching with valid tokens transitions to authenticated -> redirects to /home',
        () async {
      await fakeSecureStorage.saveAccessToken('valid_access_token');
      await fakeSecureStorage.saveRefreshToken('valid_refresh_token');

      final notifier = container.read(authProvider.notifier);
      await notifier.checkAuthentication();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);

      final helper = container.read(appRouterHelperProvider);
      final redirectPath =
          helper.redirect(FakeBuildContext(), MockGoRouterState('/splash'));
      expect(redirectPath, '/home');
    });

    test(
        '3. Launching with an unverified account transitions to unverified -> redirects to /resend-verification',
        () async {
      await fakeSecureStorage.saveAccessToken('valid_access_token');
      await fakeSecureStorage.saveRefreshToken('valid_refresh_token');
      fakeAuthRepository.shouldThrowEmailNotVerified = true;

      final notifier = container.read(authProvider.notifier);
      await notifier.checkAuthentication();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unverified);

      final helper = container.read(appRouterHelperProvider);
      final redirectPath =
          helper.redirect(FakeBuildContext(), MockGoRouterState('/splash'));
      expect(redirectPath, '/resend-verification');
    });

    test(
        '4. Launching with a deactivated account transitions to deactivated -> redirects to /login',
        () async {
      await fakeSecureStorage.saveAccessToken('valid_access_token');
      await fakeSecureStorage.saveRefreshToken('valid_refresh_token');
      fakeAuthRepository.shouldThrowDeactivated = true;

      final notifier = container.read(authProvider.notifier);
      await notifier.checkAuthentication();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.deactivated);

      final helper = container.read(appRouterHelperProvider);
      final redirectPath =
          helper.redirect(FakeBuildContext(), MockGoRouterState('/splash'));
      expect(redirectPath, '/login');
    });

    test(
        '5. Launching with generic error clears tokens and transitions to initial -> redirects to /login',
        () async {
      await fakeSecureStorage.saveAccessToken('valid_access_token');
      await fakeSecureStorage.saveRefreshToken('valid_refresh_token');
      fakeAuthRepository.shouldThrowGenericException = true;

      final notifier = container.read(authProvider.notifier);
      await notifier.checkAuthentication();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.initial);
      expect(await fakeSecureStorage.getAccessToken(), isNull);
      expect(await fakeSecureStorage.getRefreshToken(), isNull);

      final helper = container.read(appRouterHelperProvider);
      final redirectPath =
          helper.redirect(FakeBuildContext(), MockGoRouterState('/splash'));
      expect(redirectPath, '/login');
    });
  });

  group('Authentication Flow Action Tests', () {
    test('6. Login action success transitions to authenticated state', () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.login('testuser', 'password123', false);

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNotNull);
      expect(await fakeSecureStorage.getAccessToken(), 'mock_access');
      expect(await fakeSecureStorage.getRefreshToken(), 'mock_refresh');
    });

    test('7. Login action failure transitions to error state', () async {
      fakeAuthRepository.loginShouldFail = true;
      final notifier = container.read(authProvider.notifier);
      await notifier.login('baduser', 'wrongpass', false);

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Invalid credentials');
    });

    test('8. Logout action clears local session and transitions to initial state', () async {
      await fakeSecureStorage.saveAccessToken('stored_token');
      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.initial);
      expect(await fakeSecureStorage.getAccessToken(), isNull);
    });

    test('9. Register action success transitions to unverified state', () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.register(
        email: 'register@tarang.in',
        username: 'newrider',
        password: 'password123',
        fullName: 'New Rider',
      );

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unverified);
      expect(state.unverifiedEmail, 'register@tarang.in');
    });

    test('10. Register action failure transitions to error state', () async {
      fakeAuthRepository.registerShouldFail = true;
      final notifier = container.read(authProvider.notifier);
      await notifier.register(
        email: 'bad@tarang.in',
        username: 'badname',
        password: '123',
      );

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Registration failed');
    });
  });
}
