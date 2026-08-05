class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

class TimeoutException extends AppException {
  TimeoutException(String message) : super(message, 'TIMEOUT_ERROR');
}

class UnauthorizedException extends AppException {
  UnauthorizedException(String message, [String? code])
      : super(message, code ?? 'UNAUTHORIZED');
}

class ForbiddenException extends AppException {
  ForbiddenException(String message, [String? code])
      : super(message, code ?? 'FORBIDDEN');
}

class NotFoundException extends AppException {
  NotFoundException(String message, [String? code])
      : super(message, code ?? 'NOT_FOUND');
}

class BadRequestException extends AppException {
  BadRequestException(String message, [String? code])
      : super(message, code ?? 'BAD_REQUEST');
}

class EmailNotVerifiedException extends AppException {
  EmailNotVerifiedException(String message)
      : super(message, 'EMAIL_NOT_VERIFIED');
}

class AccountDeletedException extends AppException {
  AccountDeletedException(String message) : super(message, 'ACCOUNT_DELETED');
}

class AccountDeactivatedException extends AppException {
  final double? daysRemaining;

  AccountDeactivatedException(String message, [this.daysRemaining])
      : super(message, 'ACCOUNT_DEACTIVATED_COOL_DOWN');
}

class ServerException extends AppException {
  ServerException(String message) : super(message, 'SERVER_ERROR');
}
