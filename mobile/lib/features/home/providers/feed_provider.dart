import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/repositories/wave_repository.dart';
import 'package:mobile/core/providers/core_providers.dart';

enum FeedStatus { initial, loading, success, loadingMore, error }

class FeedState {
  final FeedStatus status;
  final List<WaveModel> waves;
  final bool hasMore;
  final String? errorMessage;
  final int skip;
  final String streamType;

  const FeedState({
    required this.status,
    required this.waves,
    required this.hasMore,
    this.errorMessage,
    required this.skip,
    required this.streamType,
  });

  const FeedState.initial()
      : status = FeedStatus.initial,
        waves = const [],
        hasMore = true,
        errorMessage = null,
        skip = 0,
        streamType = 'all';

  FeedState copyWith({
    FeedStatus? status,
    List<WaveModel>? waves,
    bool? hasMore,
    String? errorMessage,
    int? skip,
    String? streamType,
  }) {
    return FeedState(
      status: status ?? this.status,
      waves: waves ?? this.waves,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
      skip: skip ?? this.skip,
      streamType: streamType ?? this.streamType,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final WaveRepository _waveRepository;
  static const int _limit = 20;

  FeedNotifier(this._waveRepository) : super(const FeedState.initial()) {
    loadFeed();
  }

  Future<void> setStreamType(String type) async {
    if (state.streamType == type) return;
    state = state.copyWith(streamType: type, waves: [], skip: 0, hasMore: true);
    await loadFeed(refresh: true);
  }

  Future<void> loadFeed({bool refresh = false}) async {
    if (refresh) {
      state =
          state.copyWith(status: FeedStatus.loading, skip: 0, hasMore: true);
    } else {
      if (state.status == FeedStatus.loading ||
          state.status == FeedStatus.loadingMore ||
          !state.hasMore) {
        return;
      }
      state = state.copyWith(
        status:
            state.waves.isEmpty ? FeedStatus.loading : FeedStatus.loadingMore,
      );
    }

    try {
      final fetchedWaves = await _waveRepository.getWaves(
        skip: state.skip,
        limit: _limit,
        streamType: state.streamType,
      );

      final newWaves =
          refresh ? fetchedWaves : [...state.waves, ...fetchedWaves];
      state = state.copyWith(
        status: FeedStatus.success,
        waves: newWaves,
        skip: state.skip + fetchedWaves.length,
        hasMore: fetchedWaves.length >= _limit,
      );
    } catch (e) {
      state = state.copyWith(
        status: FeedStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> spreadWave(String waveId) async {
    final originalWaves = [...state.waves];
    final index = state.waves.indexWhere((w) => w.id == waveId);
    if (index == -1) return;

    final target = state.waves[index];
    final newSpreadCount = target.spreadsCount + 1;
    final updatedWaves = [...state.waves];
    updatedWaves[index] =
        target.copyWith(spreadsCount: newSpreadCount, spreadByMe: true);
    state = state.copyWith(waves: updatedWaves);

    try {
      await _waveRepository.spreadWave(waveId);
    } catch (e) {
      state = state.copyWith(waves: originalWaves);
    }
  }

  // Optimistic Ripple Updates
  Future<void> toggleRipple(String waveId) async {
    final originalWaves = [...state.waves];
    final index = state.waves.indexWhere((w) => w.id == waveId);
    if (index == -1) return;

    final target = state.waves[index];
    final newRippled = !target.rippledByMe;
    final newCount = target.ripplesCount + (newRippled ? 1 : -1);

    // Apply optimistic update
    final updatedWaves = [...state.waves];
    updatedWaves[index] = target.copyWith(
      rippledByMe: newRippled,
      ripplesCount: newCount,
    );
    state = state.copyWith(waves: updatedWaves);

    try {
      final result = await _waveRepository.toggleRipple(waveId);
      // Sync with real backend response values
      final backendRippled = result['rippled'] as bool;
      final backendCount = result['ripples_count'] as int;

      final verifiedWaves = [...state.waves];
      final targetIndex = verifiedWaves.indexWhere((w) => w.id == waveId);
      if (targetIndex != -1) {
        verifiedWaves[targetIndex] = verifiedWaves[targetIndex].copyWith(
          rippledByMe: backendRippled,
          ripplesCount: backendCount,
        );
        state = state.copyWith(waves: verifiedWaves);
      }
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(waves: originalWaves);
    }
  }

  // Optimistic Bookmark Updates
  Future<void> toggleBookmark(String waveId) async {
    final originalWaves = [...state.waves];
    final index = state.waves.indexWhere((w) => w.id == waveId);
    if (index == -1) return;

    final target = state.waves[index];
    final newBookmarked = !target.bookmarkedByMe;

    final updatedWaves = [...state.waves];
    updatedWaves[index] = target.copyWith(bookmarkedByMe: newBookmarked);
    state = state.copyWith(waves: updatedWaves);

    try {
      await _waveRepository.bookmarkWave(waveId, add: newBookmarked);
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(waves: originalWaves);
    }
  }

  // Optimistic Wave Deletion
  Future<void> deleteWave(String waveId) async {
    final originalWaves = [...state.waves];
    final updatedWaves = state.waves.where((w) => w.id != waveId).toList();
    state = state.copyWith(waves: updatedWaves);

    try {
      await _waveRepository.deleteWave(waveId);
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(waves: originalWaves);
    }
  }

  // Optimistic Poll Voting
  Future<void> votePoll(String waveId, String optionId) async {
    final originalWaves = [...state.waves];
    final index = state.waves.indexWhere((w) => w.id == waveId);
    if (index == -1) return;

    final target = state.waves[index];
    final poll = target.poll;
    if (poll == null || poll.hasVoted) return;

    // Apply optimistic updates locally
    final updatedOptions = poll.options.map((opt) {
      if (opt.id == optionId) {
        return opt.copyWith(votesCount: opt.votesCount + 1, votedByMe: true);
      }
      return opt;
    }).toList();

    final updatedPoll = poll.copyWith(
      options: updatedOptions,
      totalVotes: poll.totalVotes + 1,
      hasVoted: true,
      votedOptionId: optionId,
    );

    final updatedWaves = [...state.waves];
    updatedWaves[index] = target.copyWith(poll: updatedPoll);
    state = state.copyWith(waves: updatedWaves);

    try {
      final updatedWave = await _waveRepository.votePoll(waveId, optionId);

      // Update with exact server values
      final verifiedWaves = [...state.waves];
      final targetIndex = verifiedWaves.indexWhere((w) => w.id == waveId);
      if (targetIndex != -1) {
        verifiedWaves[targetIndex] = updatedWave;
        state = state.copyWith(waves: verifiedWaves);
      }
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(waves: originalWaves);
    }
  }

  // Add/Update Wave in feed locally on create or edit success
  void addOrUpdateWave(WaveModel wave) {
    final index = state.waves.indexWhere((w) => w.id == wave.id);
    if (index != -1) {
      final updatedWaves = [...state.waves];
      updatedWaves[index] = wave;
      state = state.copyWith(waves: updatedWaves);
    } else {
      state = state.copyWith(waves: [wave, ...state.waves]);
    }
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final waveRepo = ref.watch(waveRepositoryProvider);
  return FeedNotifier(waveRepo);
});
