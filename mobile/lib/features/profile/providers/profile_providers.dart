import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/repositories/user_repository.dart';
import 'package:mobile/core/repositories/wave_repository.dart';

// ─── 1. Profile Details State ───
class ProfileState {
  final bool isLoading;
  final String? errorMessage;
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? location;
  final String? website;
  final DateTime? createdAt;
  final int waveCount;
  final int ridersCount;
  final int ridingCount;
  final bool isRiding;
  final List<WaveModel> waves;

  const ProfileState({
    required this.isLoading,
    this.errorMessage,
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.location,
    this.website,
    this.createdAt,
    required this.waveCount,
    required this.ridersCount,
    required this.ridingCount,
    required this.isRiding,
    required this.waves,
  });

  const ProfileState.initial()
      : isLoading = false,
        errorMessage = null,
        id = '',
        username = '',
        fullName = null,
        avatarUrl = null,
        coverUrl = null,
        bio = null,
        location = null,
        website = null,
        createdAt = null,
        waveCount = 0,
        ridersCount = 0,
        ridingCount = 0,
        isRiding = false,
        waves = const [];

  ProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? location,
    String? website,
    DateTime? createdAt,
    int? waveCount,
    int? ridersCount,
    int? ridingCount,
    bool? isRiding,
    List<WaveModel>? waves,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      createdAt: createdAt ?? this.createdAt,
      waveCount: waveCount ?? this.waveCount,
      ridersCount: ridersCount ?? this.ridersCount,
      ridingCount: ridingCount ?? this.ridingCount,
      isRiding: isRiding ?? this.isRiding,
      waves: waves ?? this.waves,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final UserRepository _userRepo;
  final WaveRepository _waveRepo;
  final String _username;

  ProfileNotifier(this._userRepo, this._waveRepo, this._username)
      : super(const ProfileState.initial()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _userRepo.getUserProfile(_username);

      // Fetch waves stream and filter locally by author username as in web app
      final allWaves = await _waveRepo.getWaves(skip: 0, limit: 100);
      final filteredWaves =
          allWaves.where((w) => w.creator.username == _username).toList();

      state = ProfileState(
        isLoading: false,
        errorMessage: null,
        id: profile['id'] as String,
        username: profile['username'] as String,
        fullName: profile['full_name'] as String?,
        avatarUrl: profile['avatar_url'] as String?,
        coverUrl: profile['cover_url'] as String?,
        bio: profile['bio'] as String?,
        location: profile['location'] as String?,
        website: profile['website'] as String?,
        createdAt: DateTime.parse(profile['created_at'] as String),
        waveCount: profile['wave_count'] as int? ?? 0,
        ridersCount: profile['riders_count'] as int? ?? 0,
        ridingCount: profile['riding_count'] as int? ?? 0,
        isRiding: profile['is_riding'] as bool? ?? false,
        waves: filteredWaves,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Toggle follow/ride inside profile (Optimistic)
  Future<void> toggleRide() async {
    final originalIsRiding = state.isRiding;
    final originalRidersCount = state.ridersCount;
    final newIsRiding = !state.isRiding;
    final newCount = state.ridersCount + (newIsRiding ? 1 : -1);

    state = state.copyWith(
      isRiding: newIsRiding,
      ridersCount: newCount,
    );

    try {
      final result = await _userRepo.toggleRide(state.id);
      final verifiedIsRiding = result['riding'] as bool;

      // Sync with real backend verified state
      if (state.isRiding != verifiedIsRiding) {
        state = state.copyWith(
          isRiding: verifiedIsRiding,
          ridersCount: originalRidersCount + (verifiedIsRiding ? 1 : -1),
        );
      }
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(
        isRiding: originalIsRiding,
        ridersCount: originalRidersCount,
      );
    }
  }
}

final profileProvider =
    StateNotifierProvider.family<ProfileNotifier, ProfileState, String>(
        (ref, username) {
  final userRepo = ref.watch(userRepositoryProvider);
  final waveRepo = ref.watch(waveRepositoryProvider);
  return ProfileNotifier(userRepo, waveRepo, username);
});

// ─── 2. Edit Profile State ───
class EditProfileState {
  final bool isSubmitting;
  final double uploadProgress;
  final String? errorMessage;
  final bool isSuccess;

  const EditProfileState({
    required this.isSubmitting,
    required this.uploadProgress,
    this.errorMessage,
    required this.isSuccess,
  });

  const EditProfileState.initial()
      : isSubmitting = false,
        uploadProgress = 0.0,
        errorMessage = null,
        isSuccess = false;

  EditProfileState copyWith({
    bool? isSubmitting,
    double? uploadProgress,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return EditProfileState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final UserRepository _userRepo;

  EditProfileNotifier(this._userRepo) : super(const EditProfileState.initial());

  Future<void> updateProfile({
    required String fullName,
    required String username,
    required String bio,
    String? avatarPath,
    String? bannerPath,
  }) async {
    state = state.copyWith(
        isSubmitting: true, errorMessage: null, isSuccess: false);
    try {
      String? avatarUrl;
      String? coverUrl;

      // Handle file uploads if local path exists
      if (avatarPath != null && avatarPath.isNotEmpty) {
        state = state.copyWith(uploadProgress: 0.3);
        avatarUrl = await _userRepo.uploadMedia(avatarPath);
      }
      if (bannerPath != null && bannerPath.isNotEmpty) {
        state = state.copyWith(uploadProgress: 0.6);
        coverUrl = await _userRepo.uploadMedia(bannerPath);
      }

      state = state.copyWith(uploadProgress: 0.9);
      await _userRepo.updateProfile(
        fullName: fullName,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      );

      state = const EditProfileState(
        isSubmitting: false,
        uploadProgress: 1.0,
        isSuccess: true,
        errorMessage: null,
      );
    } catch (e) {
      state = EditProfileState(
        isSubmitting: false,
        uploadProgress: 0.0,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final editProfileProvider =
    StateNotifierProvider<EditProfileNotifier, EditProfileState>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  return EditProfileNotifier(userRepo);
});

// ─── 3. Follow Graph Lists (Riders / Riding) ───
class FollowListState {
  final bool isLoading;
  final List<UserModel> list;
  final String? errorMessage;

  const FollowListState({
    required this.isLoading,
    required this.list,
    this.errorMessage,
  });

  const FollowListState.initial()
      : isLoading = false,
        list = const [],
        errorMessage = null;

  FollowListState copyWith({
    bool? isLoading,
    List<UserModel>? list,
    String? errorMessage,
  }) {
    return FollowListState(
      isLoading: isLoading ?? this.isLoading,
      list: list ?? this.list,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FollowersNotifier extends StateNotifier<FollowListState> {
  final UserRepository _userRepo;
  final String _userId;

  FollowersNotifier(this._userRepo, this._userId)
      : super(const FollowListState.initial()) {
    loadFollowers();
  }

  Future<void> loadFollowers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _userRepo.getFollowers(_userId);
      state = FollowListState(isLoading: false, list: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

class FollowingNotifier extends StateNotifier<FollowListState> {
  final UserRepository _userRepo;
  final String _userId;

  FollowingNotifier(this._userRepo, this._userId)
      : super(const FollowListState.initial()) {
    loadFollowing();
  }

  Future<void> loadFollowing() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _userRepo.getFollowing(_userId);
      state = FollowListState(isLoading: false, list: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final followersProvider =
    StateNotifierProvider.family<FollowersNotifier, FollowListState, String>(
        (ref, userId) {
  final userRepo = ref.watch(userRepositoryProvider);
  return FollowersNotifier(userRepo, userId);
});

final followingProvider =
    StateNotifierProvider.family<FollowingNotifier, FollowListState, String>(
        (ref, userId) {
  final userRepo = ref.watch(userRepositoryProvider);
  return FollowingNotifier(userRepo, userId);
});
