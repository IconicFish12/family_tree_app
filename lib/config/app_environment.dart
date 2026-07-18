class AppEnvironment {
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'Tali Silsilah');

  static const String appEnvironment = String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-alusrah.oproject.id/api',
  );

  static const String storageBaseUrl = String.fromEnvironment(
    'API_STORAGE_URL',
    defaultValue: 'https://api-alusrah.oproject.id/storage/',
  );

  static const int networkTimeoutSeconds = int.fromEnvironment('NETWORK_TIMEOUT_SECONDS', defaultValue: 20);

  static bool get isProduction => appEnvironment.toLowerCase() == 'production';

  static String get normalizedStorageBaseUrl => storageBaseUrl.endsWith('/') ? storageBaseUrl : '$storageBaseUrl/';
}
