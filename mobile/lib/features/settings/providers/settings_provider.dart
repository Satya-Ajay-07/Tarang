import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/repositories/user_repository.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/features/home/providers/feed_provider.dart';
import 'package:mobile/features/notifications/providers/notification_providers.dart';

class SettingsState {
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const SettingsState({
    required this.isSubmitting,
    this.errorMessage,
    required this.isSuccess,
  });

  const SettingsState.initial()
      : isSubmitting = false,
        errorMessage = null,
        isSuccess = false;

  SettingsState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return SettingsState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final UserRepository _userRepo;
  final Ref _ref;

  SettingsNotifier(this._userRepo, this._ref)
      : super(const SettingsState.initial());

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(
        isSubmitting: true, errorMessage: null, isSuccess: false);
    try {
      await _userRepo.changePassword(currentPassword, newPassword);
      state = const SettingsState(
          isSubmitting: false, isSuccess: true, errorMessage: null);
    } catch (e) {
      state = SettingsState(
          isSubmitting: false, isSuccess: false, errorMessage: e.toString());
    }
  }

  Future<void> deactivateAccount(String password) async {
    state = state.copyWith(
        isSubmitting: true, errorMessage: null, isSuccess: false);
    try {
      await _userRepo.deactivateAccount(password);
      state = const SettingsState(
          isSubmitting: false, isSuccess: true, errorMessage: null);

      // Auto logout session on successful deactivation
      await _ref.read(authProvider.notifier).logout();
    } catch (e) {
      state = SettingsState(
          isSubmitting: false, isSuccess: false, errorMessage: e.toString());
    }
  }

  Future<void> deleteAccount(String password) async {
    state = state.copyWith(
        isSubmitting: true, errorMessage: null, isSuccess: false);
    try {
      await _userRepo.deleteAccount(password);
      state = const SettingsState(
          isSubmitting: false, isSuccess: true, errorMessage: null);

      // Auto logout on successful deletion
      await _ref.read(authProvider.notifier).logout();
    } catch (e) {
      state = SettingsState(
          isSubmitting: false, isSuccess: false, errorMessage: e.toString());
    }
  }

  void clearAppCaches() {
    // Invalidate main state caches to reset providers
    _ref.invalidate(feedProvider);
    _ref.invalidate(notificationProvider);
    _ref.invalidate(bookmarkProvider);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  return SettingsNotifier(userRepo, ref);
});
