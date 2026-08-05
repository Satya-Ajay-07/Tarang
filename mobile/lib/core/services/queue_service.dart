import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/repositories/wave_repository.dart';
import 'package:mobile/core/repositories/user_repository.dart';

class QueueItem {
  final String id;
  final String action; // ripple, bookmark, follow, create_wave
  final Map<String, dynamic> params;

  const QueueItem({
    required this.id,
    required this.action,
    required this.params,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'params': params,
      };

  factory QueueItem.fromJson(Map<String, dynamic> json) => QueueItem(
        id: json['id'] as String,
        action: json['action'] as String,
        params: json['params'] as Map<String, dynamic>,
      );
}

class QueueService {
  final FlutterSecureStorage _storage;
  final WaveRepository _waveRepo;
  final UserRepository _userRepo;

  QueueService(this._storage, this._waveRepo, this._userRepo);

  static const _key = 'offline_sync_queue';

  Future<List<QueueItem>> getQueue() async {
    try {
      final value = await _storage.read(key: _key);
      if (value == null) return const [];
      final list = jsonDecode(value) as List<dynamic>;
      return list.map((e) => QueueItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> addToQueue(String action, Map<String, dynamic> params) async {
    final queue = await getQueue();
    final item = QueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      params: params,
    );
    final updated = [...queue, item];
    await _storage.write(key: _key, value: jsonEncode(updated.map((e) => e.toJson()).toList()));
  }

  Future<void> processQueue() async {
    final queue = await getQueue();
    if (queue.isEmpty) return;

    final remaining = <QueueItem>[];

    for (final item in queue) {
      try {
        switch (item.action) {
          case 'ripple':
            final waveId = item.params['wave_id'] as String;
            await _waveRepo.toggleRipple(waveId);
            break;
          case 'bookmark':
            final waveId = item.params['wave_id'] as String;
            final add = item.params['add'] as bool;
            await _waveRepo.bookmarkWave(waveId, add: add);
            break;
          case 'follow':
            final userId = item.params['user_id'] as String;
            await _userRepo.toggleRide(userId);
            break;
          case 'create_wave':
            await _waveRepo.createWave(
              content: item.params['content'] as String?,
              mediaUrl: item.params['media_url'] as String?,
              mediaType: item.params['media_type'] as String?,
              parentWaveId: item.params['parent_wave_id'] as String?,
              circleId: item.params['circle_id'] as String?,
              spreadFromId: item.params['spread_from_id'] as String?,
            );
            break;
        }
      } catch (e) {
        // In case of permanent API errors (e.g. 404, 400), don't retry forever, discard.
        // Otherwise, keep in queue for next sync interval.
        if (e.toString().contains('400') || e.toString().contains('404') || e.toString().contains('403')) {
          continue; // Discard item
        }
        remaining.add(item);
      }
    }

    await _storage.write(key: _key, value: jsonEncode(remaining.map((e) => e.toJson()).toList()));
  }
}
