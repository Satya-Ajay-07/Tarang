import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/exceptions/app_exceptions.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService _secureStorage;
  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5, lineLength: 90, colors: true, printEmojis: true),
    level: kDebugMode ? Level.debug : Level.warning,
  );

  ApiClient(this._secureStorage) : dio = Dio() {
    dio.options.baseUrl = AppConfig.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 13);
    dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // 1. Logging Interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          _logger.i('REQUEST[${options.method}] => PATH: ${options.path}');
          final cleanHeaders = Map<String, dynamic>.from(options.headers);
          if (cleanHeaders.containsKey('Authorization')) {
            cleanHeaders['Authorization'] = 'Bearer [REDACTED]';
          }
          _logger.d('Headers: $cleanHeaders');
          if (options.data != null) {
            _logger.d('Body: ${options.data}');
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          _logger.i('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          _logger.d('Data: ${response.data}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          _logger.e('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          _logger.d('Error Message: ${e.message}');
          if (e.response?.data != null) {
            _logger.d('Error Data: ${e.response?.data}');
          }
        }
        return handler.next(e);
      },
    ));

    // 2. Authorization Interceptor (JWT Attachment)
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth header for endpoints that don't need it
        if (options.path.contains('/auth/login') ||
            options.path.contains('/auth/register') ||
            options.path.contains('/auth/forgot-password') ||
            options.path.contains('/auth/reset-password')) {
          return handler.next(options);
        }

        final accessToken = await _secureStorage.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
    ));

    // 3. Refresh Token Interceptor (401 Handler with retry)
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException error, handler) async {
        final requestOptions = error.requestOptions;

        // Check if we got a 401 Unauthorized and it's not a login or refresh request
        if (error.response?.statusCode == 401 &&
            !requestOptions.path.contains('/auth/login') &&
            !requestOptions.path.contains('/auth/refresh')) {
          
          try {
            final refreshed = await refreshToken();
            if (refreshed) {
              // Retry the failed request with the new access token
              final newAccessToken = await _secureStorage.getAccessToken();
              requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              
              final response = await dio.fetch(requestOptions);
              return handler.resolve(response);
            }
          } catch (e) {
            _logger.e('Failed to refresh token: $e');
          }
        }

        return handler.next(error);
      },
    ));
  }

  // Refreshes access token synchronously via the API and saves the new pair
  Future<bool> refreshToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      // Create a clean Dio instance to avoid interceptor circular loops
      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: {
          'Authorization': 'Bearer $refreshToken',
          'Accept': 'application/json',
        },
      ));

      final response = await refreshDio.post('/auth/refresh');
      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken = data['refresh_token'] as String;

        await _secureStorage.saveAccessToken(newAccessToken);
        await _secureStorage.saveRefreshToken(newRefreshToken);
        _logger.i('Tokens refreshed and saved successfully.');
        return true;
      }
    } catch (e) {
      _logger.e('Token refresh API call failed: $e');
    }

    // If refresh fails, clear storage
    await _secureStorage.deleteAccessToken();
    await _secureStorage.deleteRefreshToken();
    return false;
  }

  // Parse and wrap DioException to custom AppExceptions
  AppException handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return TimeoutException('Connection timed out. Please try again.');
    }

    if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
      return NetworkException('No internet connection. Please verify your connection.');
    }

    final response = e.response;
    if (response != null) {
      final statusCode = response.statusCode;
      final data = response.data;
      String message = 'Something went wrong';
      String? code;

      if (data is Map<String, dynamic> && data['error'] != null) {
        final err = data['error'];
        if (err is Map<String, dynamic>) {
          message = err['message'] ?? message;
          code = err['code']?.toString();
        }
      } else if (data is Map<String, dynamic> && data['detail'] != null) {
        message = data['detail'].toString();
      }

      if (code == 'ACCOUNT_DELETED') {
        return AccountDeletedException(message);
      }
      if (code == 'ACCOUNT_DEACTIVATED_COOL_DOWN') {
        final days = (data['error'] as Map<String, dynamic>?)?['days_remaining'];
        double? daysRemaining;
        if (days != null) {
          daysRemaining = double.tryParse(days.toString());
        }
        return AccountDeactivatedException(message, daysRemaining);
      }
      if (code == 'EMAIL_NOT_VERIFIED') {
        return EmailNotVerifiedException(message);
      }

      switch (statusCode) {
        case 400:
          return BadRequestException(message, code);
        case 401:
          return UnauthorizedException(message, code);
        case 403:
          return ForbiddenException(message, code);
        case 404:
          return NotFoundException(message, code);
        case 500:
          return ServerException('Internal Server Error. Please contact support.');
        default:
          return AppException(message, code);
      }
    }

    return AppException('An unexpected error occurred: ${e.message}');
  }
}
