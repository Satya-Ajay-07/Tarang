import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SecureStorageService _secureStorage;

  ThemeNotifier(this._secureStorage) : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = await _secureStorage.getThemePreference();
    if (theme == 'light') {
      state = ThemeMode.light;
    } else if (theme == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await _secureStorage.saveThemePreference('light');
    } else {
      state = ThemeMode.dark;
      await _secureStorage.saveThemePreference('dark');
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    String value = 'system';
    if (mode == ThemeMode.light) value = 'light';
    if (mode == ThemeMode.dark) value = 'dark';
    await _secureStorage.saveThemePreference(value);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return ThemeNotifier(secureStorage);
});
