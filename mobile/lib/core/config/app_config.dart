class AppConfig {
  static const String devBaseUrl =
      'https://tarang-production.up.railway.app/api/v1';

  static const String prodBaseUrl =
      'https://tarang-production.up.railway.app/api/v1';

  static const bool isProduction = true;

  static String get baseUrl =>
      isProduction ? prodBaseUrl : devBaseUrl;
}