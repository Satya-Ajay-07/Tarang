import 'package:dio/dio.dart';
import 'package:mobile/core/models/alert_model.dart';
import 'package:mobile/core/network/api_client.dart';

abstract class AlertRepository {
  Future<List<AlertModel>> getAlerts({int skip = 0, int limit = 50});
  Future<Map<String, dynamic>> markAllRead();
  Future<Map<String, dynamic>> markRead(String alertId);
  Future<Map<String, dynamic>> deleteAlert(String alertId);
}

class AlertRepositoryImpl implements AlertRepository {
  final ApiClient _apiClient;

  AlertRepositoryImpl(this._apiClient);

  @override
  Future<List<AlertModel>> getAlerts({int skip = 0, int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get(
        '/alerts',
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> markAllRead() async {
    try {
      final response = await _apiClient.dio.post('/alerts/read');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> markRead(String alertId) async {
    try {
      final response = await _apiClient.dio.post('/alerts/$alertId/read');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> deleteAlert(String alertId) async {
    try {
      final response = await _apiClient.dio.delete('/alerts/$alertId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}
