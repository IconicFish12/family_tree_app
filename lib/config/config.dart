import 'package:dio/dio.dart';
import 'package:family_tree_app/config/app_environment.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef UnauthorizedHandler = Future<void> Function(String reason);

class Config {
  static const Color primary = Color(0xFF1FA15D);
  static const Color primaryDark = Color(0xFF0C5531);
  static const Color accent = Color(0xFF4AB97A);
  static const Color secondarySoft = Color(0xFFE8F5EE);
  static const Color background = Color(0xFFF3F3F3);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textHead = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF5F5F64);

  static const String fontFamily = 'Albert Sans';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  static const String baseUrl = AppEnvironment.apiBaseUrl;
  static String get baseStorageUrl => AppEnvironment.normalizedStorageBaseUrl;

  static String? _accessToken;
  static UnauthorizedHandler? _unauthorizedHandler;
  static bool _isHandlingUnauthorized = false;

  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: const {'Accept': 'application/json'},
            connectTimeout: Duration(
              seconds: AppEnvironment.networkTimeoutSeconds,
            ),
            receiveTimeout: Duration(
              seconds: AppEnvironment.networkTimeoutSeconds,
            ),
            sendTimeout: Duration(
              seconds: AppEnvironment.networkTimeoutSeconds,
            ),
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (_accessToken != null && _accessToken!.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $_accessToken';
              } else {
                options.headers.remove('Authorization');
              }
              handler.next(options);
            },
            onError: (error, handler) async {
              final statusCode = error.response?.statusCode;
              final requestPath = error.requestOptions.path;
              final skipHandler =
                  error.requestOptions.extra['skipUnauthorizedHandler'] == true;

              final shouldHandleUnauthorized =
                  !skipHandler &&
                  statusCode == 401 &&
                  !requestPath.endsWith('/users/login') &&
                  !requestPath.endsWith('/users/logout');

              if (shouldHandleUnauthorized &&
                  !_isHandlingUnauthorized &&
                  _unauthorizedHandler != null) {
                _isHandlingUnauthorized = true;
                try {
                  await _unauthorizedHandler!(
                    'Sesi login berakhir. Silakan login kembali.',
                  );
                } finally {
                  _isHandlingUnauthorized = false;
                }
              }

              handler.next(error);
            },
          ),
        );

  static void setAccessToken(String? token) {
    _accessToken = token?.trim().isEmpty == true ? null : token?.trim();
  }

  static void registerUnauthorizedHandler(UnauthorizedHandler? handler) {
    _unauthorizedHandler = handler;
  }

  static String? getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$baseStorageUrl$path';
  }

  ThemeData get lightTheme {
    return ThemeData(
      primaryColor: Config.primary,
      scaffoldBackgroundColor: Config.background,
      colorScheme: ColorScheme.light(
        primary: Config.primary,
        onPrimary: Config.white,
        secondary: Config.accent,
        onSecondary: Config.white,
        surface: Config.white,
        onSurface: Config.textHead,
        error: Colors.red.shade700,
        onError: Config.white,
      ),
      textTheme: GoogleFonts.albertSansTextTheme(
        TextTheme(
          headlineMedium: TextStyle(
            color: Config.textHead,
            fontWeight: Config.semiBold,
          ),
          bodyLarge: TextStyle(
            color: Config.textHead,
            fontWeight: Config.regular,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: Config.textSecondary,
            fontWeight: Config.regular,
          ),
          labelLarge: TextStyle(color: Config.white, fontWeight: Config.medium),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Config.primary,
        foregroundColor: Config.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.albertSans(
          fontSize: 20,
          fontWeight: Config.semiBold,
          color: Config.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Config.primary,
          foregroundColor: Config.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.albertSans(
            fontWeight: Config.medium,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
