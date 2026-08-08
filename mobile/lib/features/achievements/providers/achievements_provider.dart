import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/achievement_model.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/providers/core_providers.dart';

enum AchievementsStatus { initial, loading, loaded, error }

class AchievementsState {
  final List<AchievementModel> achievements;
  final AchievementsStatus status;
  final String? errorMessage;
  final AchievementModel? newlyUnlocked;

  AchievementsState({
    required this.achievements,
    required this.status,
    this.errorMessage,
    this.newlyUnlocked,
  });

  AchievementsState copyWith({
    List<AchievementModel>? achievements,
    AchievementsStatus? status,
    String? errorMessage,
    AchievementModel? newlyUnlocked,
    bool clearNewlyUnlocked = false,
  }) {
    return AchievementsState(
      achievements: achievements ?? this.achievements,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      newlyUnlocked: clearNewlyUnlocked ? null : (newlyUnlocked ?? this.newlyUnlocked),
    );
  }
}

class AchievementsNotifier extends StateNotifier<AchievementsState> {
  final ApiClient _apiClient;
  final String? _targetUsername;

  AchievementsNotifier(this._apiClient, this._targetUsername)
      : super(AchievementsState(achievements: [], status: AchievementsStatus.initial)) {
    loadAchievements();
  }

  Future<void> loadAchievements() async {
    state = state.copyWith(status: AchievementsStatus.loading);
    try {
      final endpoint = _targetUsername != null
          ? '/achievements/$_targetUsername'
          : '/achievements/me';
      
      final response = await _apiClient.dio.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final list = data.map((json) => AchievementModel.fromJson(json)).toList();
        state = state.copyWith(achievements: list, status: AchievementsStatus.loaded);
      } else {
        state = state.copyWith(
          status: AchievementsStatus.error,
          errorMessage: 'Failed to retrieve achievements',
        );
      }
    } catch (err) {
      state = state.copyWith(
        status: AchievementsStatus.error,
        errorMessage: err.toString(),
      );
    }
  }

  Future<void> checkAndAward() async {
    // Only run for current user profile
    if (_targetUsername != null) return;
    try {
      final response = await _apiClient.dio.post('/achievements/check', data: {});
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic>? newly = data['newly_unlocked'];
        if (newly != null && newly.isNotEmpty) {
          final unlocked = AchievementModel.fromJson(newly.first);
          state = state.copyWith(newlyUnlocked: unlocked);
          // Reload to refresh the list
          await loadAchievements();
        }
      }
    } catch (err) {
      // non-blocking
    }
  }

  void clearNewlyUnlocked() {
    state = state.copyWith(clearNewlyUnlocked: true);
  }
}

final achievementsProviderFamily = StateNotifierProvider.family<AchievementsNotifier, AchievementsState, String?>((ref, username) {
  final apiClient = ref.watch(apiClientProvider);
  return AchievementsNotifier(apiClient, username);
});
