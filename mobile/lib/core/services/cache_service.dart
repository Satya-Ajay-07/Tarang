import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheService {
  final FlutterSecureStorage _storage;

  const CacheService(this._storage);

  Future<void> cacheData(String key, dynamic data,
      {Duration ttl = const Duration(hours: 2)}) async {
    final payload = {
      'cached_at': DateTime.now().toIso8601String(),
      'ttl_seconds': ttl.inSeconds,
      'data': data,
    };
    await _storage.write(key: 'cache_$key', value: jsonEncode(payload));
  }

  Future<dynamic> getCachedData(String key) async {
    try {
      final value = await _storage.read(key: 'cache_$key');
      if (value == null) return null;

      final payload = jsonDecode(value) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(payload['cached_at'] as String);
      final ttlSeconds = payload['ttl_seconds'] as int;

      // Check if cache expired
      if (DateTime.now().difference(cachedAt).inSeconds > ttlSeconds) {
        return null; // Stale, let caller revalidate
      }

      return payload['data'];
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache(String key) async {
    await _storage.delete(key: 'cache_$key');
  }

  Future<void> clearAllCaches() async {
    final allKeys = await _storage.readAll();
    for (final k in allKeys.keys) {
      if (k.startsWith('cache_')) {
        await _storage.delete(key: k);
      }
    }
  }
}
