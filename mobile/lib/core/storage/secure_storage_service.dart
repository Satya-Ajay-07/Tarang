import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveThemePreference(String theme) async {
    await _storage.write(key: AppConstants.themeKey, value: theme);
  }

  Future<String?> getThemePreference() async {
    return await _storage.read(key: AppConstants.themeKey);
  }

  Future<void> saveRememberMe(bool remember) async {
    await _storage.write(
        key: AppConstants.rememberMeKey, value: remember.toString());
  }

  Future<bool> getRememberMe() async {
    final val = await _storage.read(key: AppConstants.rememberMeKey);
    return val == 'true';
  }

  Future<void> saveCredentials(String usernameOrEmail, String password) async {
    await _storage.write(
        key: AppConstants.savedUsernameOrEmailKey, value: usernameOrEmail);
    await _storage.write(key: AppConstants.savedPasswordKey, value: password);
  }

  Future<Map<String, String?>> getCredentials() async {
    final usernameOrEmail =
        await _storage.read(key: AppConstants.savedUsernameOrEmailKey);
    final password = await _storage.read(key: AppConstants.savedPasswordKey);
    return {
      'usernameOrEmail': usernameOrEmail,
      'password': password,
    };
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: AppConstants.savedUsernameOrEmailKey);
    await _storage.delete(key: AppConstants.savedPasswordKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
