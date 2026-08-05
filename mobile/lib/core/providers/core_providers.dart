import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/core/repositories/authentication_repository.dart';
import 'package:mobile/core/repositories/wave_repository.dart';
import 'package:mobile/core/repositories/explore_repository.dart';
import 'package:mobile/core/repositories/user_repository.dart';
import 'package:mobile/core/repositories/alert_repository.dart';
import 'package:mobile/core/services/cache_service.dart';
import 'package:mobile/core/services/draft_service.dart';
import 'package:mobile/core/services/queue_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SecureStorageService(storage);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return ApiClient(storageService);
});

final authRepositoryProvider = Provider<AuthenticationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthenticationRepositoryImpl(apiClient);
});

final waveRepositoryProvider = Provider<WaveRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WaveRepositoryImpl(apiClient);
});

final exploreRepositoryProvider = Provider<ExploreRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExploreRepositoryImpl(apiClient);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepositoryImpl(apiClient);
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AlertRepositoryImpl(apiClient);
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return CacheService(storage);
});

final draftServiceProvider = Provider<DraftService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DraftService(storage);
});

final queueServiceProvider = Provider<QueueService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final waveRepo = ref.watch(waveRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  return QueueService(storage, waveRepo, userRepo);
});
