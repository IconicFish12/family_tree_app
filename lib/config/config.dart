import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Config {
  // Warna Utama
  static const Color primary = Color(0xFF1FA15D);
  static const Color primaryDark = Color(0xFF0C5531);

  // Warna Aksen & Sekunder
  static const Color accent = Color(0xFF4AB97A);
  static const Color secondarySoft = Color(0xFFE8F5EE);

  // Warna Latar Belakang & Netral
  static const Color background = Color(0xFFF3F3F3);
  static const Color white = Color(0xFFFFFFFF);

  // Warna Teks
  static const Color textHead = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF5F5F64);

  static const String fontFamily = 'Albert Sans';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Dio API Fetching
  static const String baseUrl = 'https://api-alusrah.oproject.id/api';
  static final Dio dio = Dio();

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
          // Contoh kustomisasi (jika diperlukan)
          // Judul Halaman Besar
          headlineMedium: TextStyle(
            color: Config.textHead,
            fontWeight: Config.semiBold,
          ),
          // Teks Body Utama
          bodyLarge: TextStyle(
            color: Config.textHead,
            fontWeight: Config.regular,
            height: 1.5, // Spasi baris agar mudah dibaca
          ),
          // Teks Body Sekunder
          bodyMedium: TextStyle(
            color: Config.textSecondary,
            fontWeight: Config.regular,
          ),
          // Teks untuk Tombol
          labelLarge: TextStyle(color: Config.white, fontWeight: Config.medium),
        ),
      ),

      // Atur Tema AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Config.primary,
        foregroundColor: Config.white, // Warna ikon dan tombol back
        elevation: 0,
        titleTextStyle: GoogleFonts.albertSans(
          fontSize: 20,
          fontWeight: Config.semiBold,
          color: Config.white,
        ),
      ),

      // Atur Tema Tombol
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
