import 'package:dio/dio.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/network/api_client.dart';

abstract class WaveRepository {
  Future<List<WaveModel>> getWaves({int skip = 0, int limit = 20, String streamType = 'all'});
  Future<WaveModel> getWave(String waveId);
  Future<WaveModel> createWave({
    String? content,
    String? mediaUrl,
    String? mediaType,
    String? parentWaveId,
    String? circleId,
    String? spreadFromId,
    Map<String, dynamic>? poll,
  });
  Future<WaveModel> updateWave(String waveId, {String? content, String? mediaUrl, String? mediaType});
  Future<void> deleteWave(String waveId);
  Future<Map<String, dynamic>> toggleRipple(String waveId);
  Future<Map<String, dynamic>> spreadWave(String waveId);
  Future<Map<String, dynamic>> bookmarkWave(String waveId, {required bool add});
  Future<WaveModel> votePoll(String waveId, String optionId);
  Future<List<WaveModel>> getBookmarks();
}

class WaveRepositoryImpl implements WaveRepository {
  final ApiClient _apiClient;

  WaveRepositoryImpl(this._apiClient);

  @override
  Future<List<WaveModel>> getWaves({int skip = 0, int limit = 20, String streamType = 'all'}) async {
    try {
      final response = await _apiClient.dio.get(
        '/waves',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          'stream_type': streamType,
        },
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => WaveModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<WaveModel> getWave(String waveId) async {
    try {
      final response = await _apiClient.dio.get('/waves/$waveId');
      return WaveModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<WaveModel> createWave({
    String? content,
    String? mediaUrl,
    String? mediaType,
    String? parentWaveId,
    String? circleId,
    String? spreadFromId,
    Map<String, dynamic>? poll,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/waves',
        data: {
          if (content != null) 'content': content,
          if (mediaUrl != null) 'media_url': mediaUrl,
          if (mediaType != null) 'media_type': mediaType,
          if (parentWaveId != null) 'parent_wave_id': parentWaveId,
          if (circleId != null) 'circle_id': circleId,
          if (spreadFromId != null) 'spread_from_id': spreadFromId,
          if (poll != null) 'poll': poll,
        },
      );
      return WaveModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<WaveModel> updateWave(String waveId, {String? content, String? mediaUrl, String? mediaType}) async {
    try {
      final response = await _apiClient.dio.put(
        '/waves/$waveId',
        data: {
          if (content != null) 'content': content,
          if (mediaUrl != null) 'media_url': mediaUrl,
          if (mediaType != null) 'media_type': mediaType,
        },
      );
      return WaveModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<void> deleteWave(String waveId) async {
    try {
      await _apiClient.dio.delete('/waves/$waveId');
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> toggleRipple(String waveId) async {
    try {
      final response = await _apiClient.dio.post('/waves/$waveId/ripple');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> spreadWave(String waveId) async {
    try {
      final response = await _apiClient.dio.post('/waves/$waveId/spread');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> bookmarkWave(String waveId, {required bool add}) async {
    try {
      final response = add
          ? await _apiClient.dio.post('/waves/$waveId/bookmark')
          : await _apiClient.dio.delete('/waves/$waveId/bookmark');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<WaveModel> votePoll(String waveId, String optionId) async {
    try {
      final response = await _apiClient.dio.post('/waves/$waveId/poll/vote/$optionId');
      return WaveModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<List<WaveModel>> getBookmarks() async {
    try {
      final response = await _apiClient.dio.get('/waves/bookmarks');
      final list = response.data as List<dynamic>;
      return list.map((e) => WaveModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}
