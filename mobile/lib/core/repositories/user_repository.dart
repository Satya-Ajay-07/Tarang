import 'package:dio/dio.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/network/api_client.dart';

abstract class UserRepository {
  Future<Map<String, dynamic>> getUserProfile(String username);
  Future<UserModel> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
  });
  Future<String> uploadMedia(String filePath);
  Future<List<UserModel>> getFollowers(String userId);
  Future<List<UserModel>> getFollowing(String userId);
  Future<Map<String, dynamic>> toggleRide(String userId);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> deactivateAccount(String password);
  Future<void> deleteAccount(String password);
}

class UserRepositoryImpl implements UserRepository {
  final ApiClient _apiClient;

  UserRepositoryImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getUserProfile(String username) async {
    try {
      final response = await _apiClient.dio.get('/users/profile/$username');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/users/me',
        data: {
          if (fullName != null) 'full_name': fullName,
          if (username != null) 'username': username,
          if (bio != null) 'bio': bio,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (coverUrl != null) 'cover_url': coverUrl,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<String> uploadMedia(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        '/media/upload',
        data: formData,
      );
      return response.data['url'] as String;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final response = await _apiClient.dio.get('/users/$userId/riders');
      final list = response.data as List<dynamic>;
      return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final response = await _apiClient.dio.get('/users/$userId/riding');
      final list = response.data as List<dynamic>;
      return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
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

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiClient.dio.post(
        '/users/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<void> deactivateAccount(String password) async {
    try {
      await _apiClient.dio.post(
        '/users/deactivate',
        data: {
          'password': password,
        },
      );
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<void> deleteAccount(String password) async {
    try {
      await _apiClient.dio.delete(
        '/users/me',
        data: {
          'password': password,
        },
      );
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}
