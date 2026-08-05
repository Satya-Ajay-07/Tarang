import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/trending_hashtag_model.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/repositories/explore_repository.dart';
import 'package:mobile/core/repositories/wave_repository.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

// ─── 1. Explore State ───
class ExploreState {
  final bool isLoading;
  final List<UserModel> suggestedRiders;
  final List<TrendingHashtagModel> trendingHashtags;
  final List<WaveModel> trendingWaves;
  final String? errorMessage;

  const ExploreState({
    required this.isLoading,
    required this.suggestedRiders,
    required this.trendingHashtags,
    required this.trendingWaves,
    this.errorMessage,
  });

  const ExploreState.initial()
      : isLoading = false,
        suggestedRiders = const [],
        trendingHashtags = const [],
        trendingWaves = const [],
        errorMessage = null;

  ExploreState copyWith({
    bool? isLoading,
    List<UserModel>? suggestedRiders,
    List<TrendingHashtagModel>? trendingHashtags,
    List<WaveModel>? trendingWaves,
    String? errorMessage,
  }) {
    return ExploreState(
      isLoading: isLoading ?? this.isLoading,
      suggestedRiders: suggestedRiders ?? this.suggestedRiders,
      trendingHashtags: trendingHashtags ?? this.trendingHashtags,
      trendingWaves: trendingWaves ?? this.trendingWaves,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ExploreNotifier extends StateNotifier<ExploreState> {
  final ExploreRepository _exploreRepo;

  ExploreNotifier(this._exploreRepo) : super(const ExploreState.initial()) {
    loadExploreData();
  }

  Future<void> loadExploreData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final suggested = await _exploreRepo.getSuggestedRiders(limit: 5);
      final trendingTags = await _exploreRepo.getTrendingHashtags(limit: 10);
      final trendingWavesList = await _exploreRepo.getRisingWaves(limit: 10);

      state = ExploreState(
        isLoading: false,
        suggestedRiders: suggested,
        trendingHashtags: trendingTags,
        trendingWaves: trendingWavesList,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> toggleRideSuggested(String userId) async {
    final originalSuggested = [...state.suggestedRiders];

    // Optimistically remove user from suggestions list
    state = state.copyWith(
      suggestedRiders:
          state.suggestedRiders.where((u) => u.id != userId).toList(),
    );

    try {
      await _exploreRepo.toggleRide(userId);
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(suggestedRiders: originalSuggested);
    }
  }
}

final exploreProvider =
    StateNotifierProvider<ExploreNotifier, ExploreState>((ref) {
  final exploreRepo = ref.watch(exploreRepositoryProvider);
  return ExploreNotifier(exploreRepo);
});

// ─── 2. Search State ───
class SearchState {
  final bool isLoading;
  final String query;
  final List<UserModel> people;
  final List<WaveModel>
      waves; // List of enriched full waves (fetched concurrently)
  final List<String> recentSearches;
  final String? errorMessage;

  const SearchState({
    required this.isLoading,
    required this.query,
    required this.people,
    required this.waves,
    required this.recentSearches,
    this.errorMessage,
  });

  const SearchState.initial()
      : isLoading = false,
        query = '',
        people = const [],
        waves = const [],
        recentSearches = const [],
        errorMessage = null;

  SearchState copyWith({
    bool? isLoading,
    String? query,
    List<UserModel>? people,
    List<WaveModel>? waves,
    List<String>? recentSearches,
    String? errorMessage,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      people: people ?? this.people,
      waves: waves ?? this.waves,
      recentSearches: recentSearches ?? this.recentSearches,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final ExploreRepository _exploreRepo;
  final WaveRepository _waveRepo;
  final SecureStorageService _secureStorage;

  SearchNotifier(this._exploreRepo, this._waveRepo, this._secureStorage)
      : super(const SearchState.initial()) {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      await _secureStorage.getThemePreference();
    } catch (_) {}
  }

  void addRecentSearch(String search) {
    if (search.trim().isEmpty) return;
    final updated = [search, ...state.recentSearches.where((s) => s != search)]
        .take(10)
        .toList();
    state = state.copyWith(recentSearches: updated);
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: const []);
  }

  Future<void> search(String query, {String kind = 'all'}) async {
    if (query.trim().isEmpty) {
      state =
          state.copyWith(query: '', people: [], waves: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, query: query, errorMessage: null);

    try {
      final searchResult = await _exploreRepo.search(query, kind: kind);

      // Concurrently fetch the full WaveModels for the simplified search wave results
      // to supply creator avatar metadata required by the reusable WaveCard.
      final wavesList = await Future.wait(
        searchResult.waves.map((w) => _waveRepo.getWave(w.id)),
      );

      state = state.copyWith(
        isLoading: false,
        people: searchResult.people,
        waves: wavesList,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Toggle Ride/Follow inside Search Results (Optimistic)
  Future<void> toggleRideSearchResult(String userId) async {
    final originalPeople = [...state.people];
    final index = state.people.indexWhere((u) => u.id == userId);
    if (index == -1) return;

    // We can cast a local is_riding status update
    // But since the UserModel is immutable, we can re-create or ignore. Let's do optimistic:
    // UserModel currently has no direct follow flags in props, but we can manage ride state cleanly.
    try {
      await _exploreRepo.toggleRide(userId);
      // Re-trigger query to refresh profile statuses
      if (state.query.isNotEmpty) {
        search(state.query);
      }
    } catch (e) {
      state = state.copyWith(people: originalPeople);
    }
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final exploreRepo = ref.watch(exploreRepositoryProvider);
  final waveRepo = ref.watch(waveRepositoryProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return SearchNotifier(exploreRepo, waveRepo, secureStorage);
});

// ─── 3. Hashtag Page State ───
class HashtagState {
  final bool isLoading;
  final List<WaveModel> waves;
  final String? errorMessage;

  const HashtagState({
    required this.isLoading,
    required this.waves,
    this.errorMessage,
  });

  const HashtagState.initial()
      : isLoading = false,
        waves = const [],
        errorMessage = null;

  HashtagState copyWith({
    bool? isLoading,
    List<WaveModel>? waves,
    String? errorMessage,
  }) {
    return HashtagState(
      isLoading: isLoading ?? this.isLoading,
      waves: waves ?? this.waves,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class HashtagNotifier extends StateNotifier<HashtagState> {
  final ExploreRepository _exploreRepo;
  final String _tag;

  HashtagNotifier(this._exploreRepo, this._tag)
      : super(const HashtagState.initial()) {
    loadHashtagWaves();
  }

  Future<void> loadHashtagWaves() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tagClean = _tag.replaceAll('#', '');
      final list = await _exploreRepo.getWavesByHashtag(tagClean);
      state = HashtagState(
        isLoading: false,
        waves: list,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final hashtagProvider =
    StateNotifierProvider.family<HashtagNotifier, HashtagState, String>(
        (ref, tag) {
  final exploreRepo = ref.watch(exploreRepositoryProvider);
  return HashtagNotifier(exploreRepo, tag);
});
