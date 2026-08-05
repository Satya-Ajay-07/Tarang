import 'package:dio/dio.dart';
import 'package:mobile/core/models/search_result_model.dart';
import 'package:mobile/core/models/trending_hashtag_model.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/network/api_client.dart';

abstract class ExploreRepository {
  Future<List<UserModel>> getSuggestedRiders({int limit = 5});
  Future<SearchResultModel> search(String query, {String kind = 'all'});
  Future<List<TrendingHashtagModel>> getTrendingHashtags({int limit = 10});
  Future<List<TrendingHashtagModel>> searchHashtags(String query, {int limit = 10});
  Future<List<WaveModel>> getWavesByHashtag(String tag, {int skip = 0, int limit = 20});
  Future<List<WaveModel>> getRisingWaves({int limit = 10});
  Future<Map<String, dynamic>> toggleRide(String userId);
}

class ExploreRepositoryImpl implements ExploreRepository {
  final ApiClient _apiClient;

  ExploreRepositoryImpl(this._apiClient);

  @override
  Future<List<UserModel>> getSuggestedRiders({int limit = 5}) async {
    try {
      final response = await _apiClient.dio.get(
        '/explore/suggested-riders',
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<SearchResultModel> search(String query, {String kind = 'all'}) async {
    try {
      final response = await _apiClient.dio.get(
        '/explore',
        queryParameters: {
          'q': query,
          'kind': kind,
        },
      );
      return SearchResultModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<List<TrendingHashtagModel>> getTrendingHashtags({int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '/hashtags/trending',
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => TrendingHashtagModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<List<TrendingHashtagModel>> searchHashtags(String query, {int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '/hashtags/search',
        queryParameters: {
          'q': query,
          'limit': limit,
        },
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => TrendingHashtagModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<List<WaveModel>> getWavesByHashtag(String tag, {int skip = 0, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/hashtags/$tag/waves',
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => WaveModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<List<WaveModel>> getRisingWaves({int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '/waves/rising',
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => WaveModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> toggleRide(String userId) async {
    try {
      final response = await _apiClient.dio.post('/users/ride/$userId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}
