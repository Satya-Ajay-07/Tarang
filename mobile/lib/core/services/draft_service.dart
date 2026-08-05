import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DraftService {
  final FlutterSecureStorage _storage;

  const DraftService(this._storage);

  static const _key = 'wave_composer_draft';

  Future<void> saveDraft({required String content, List<String>? pollOptions, String? pollQuestion}) async {
    final payload = {
      'content': content,
      'poll_options': pollOptions,
      'poll_question': pollQuestion,
      'saved_at': DateTime.now().toIso8601String(),
    };
    await _storage.write(key: _key, value: jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> loadDraft() async {
    try {
      final value = await _storage.read(key: _key);
      if (value == null) return null;
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDraft() async {
    await _storage.delete(key: _key);
  }
}
