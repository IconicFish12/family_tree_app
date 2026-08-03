class AppEnvironment {
  static const String appName = String.fromEnvironment('APP_NAME');

  static const String appEnvironment = String.fromEnvironment('APP_ENV');

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String storageBaseUrl = String.fromEnvironment(
    'API_STORAGE_URL',
  );

  static const int networkTimeoutSeconds = int.fromEnvironment(
    'NETWORK_TIMEOUT_SECONDS',
  );

  static bool get isProduction => appEnvironment.toLowerCase() == 'production';

  static String get normalizedStorageBaseUrl =>
      storageBaseUrl.endsWith('/') ? storageBaseUrl : '$storageBaseUrl/';
}
