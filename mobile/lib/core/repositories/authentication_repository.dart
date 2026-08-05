import 'package:dio/dio.dart';
import 'package:mobile/core/models/register_response_model.dart';
import 'package:mobile/core/models/token_model.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/network/api_client.dart';

abstract class AuthenticationRepository {
  Future<TokenModel> login(String usernameOrEmail, String password);
  Future<RegisterResponseModel> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
    String? country,
    String? phoneNumber,
  });
  Future<bool> verifyEmail(String token);
  Future<bool> resendVerification(String email);
  Future<bool> forgotPassword(String email);
  Future<bool> resetPassword(String token, String newPassword);
  Future<UserModel> getMe();
  Future<void> logout(String? refreshToken);
}

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  final ApiClient _apiClient;

  AuthenticationRepositoryImpl(this._apiClient);

  @override
  Future<TokenModel> login(String usernameOrEmail, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username_or_email': usernameOrEmail,
          'password': password,
        },
      );
      return TokenModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<RegisterResponseModel> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
    String? country,
    String? phoneNumber,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'username': username,
          'password': password,
          if (fullName != null) 'full_name': fullName,
          if (country != null) 'country': country,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );
      return RegisterResponseModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<bool> verifyEmail(String token) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/verify-email',
        queryParameters: {'token': token},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<bool> resendVerification(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/resend-verification',
        data: {'email': email},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/forgot-password',
        queryParameters: {'email': email},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/reset-password',
        queryParameters: {
          'token': token,
          'new_password': newPassword,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  @override
  Future<void> logout(String? refreshToken) async {
    try {
      await _apiClient.dio.post(
        '/auth/logout',
        options: Options(
          headers: {
            if (refreshToken != null) 'Cookie': 'refresh_token=$refreshToken',
          },
        ),
      );
    } on DioException {
      // Ignored for logout to avoid blocking local session clearing
    }
  }
}
