import 'package:flutter/material.dart';

// EDIT_TARGET: app_theme.dart
// EDIT_PURPOSE: Menentukan token warna, typography, dan Material theme aplikasi.
// EDIT_REASON: FSD menetapkan visual clean, calm, technical dengan palette eksplisit.
class AppColors {
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const secondary = Color(0xFF14B8A6);
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF1F5F9);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFCBD5E1);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const offline = Color(0xFF94A3B8);
  static const debug = Color(0xFF8B5CF6);
  static const chartLine = Color(0xFF2563EB);
  static const chartLineSecondary = Color(0xFF14B8A6);
  static const chartGrid = Color(0xFFE2E8F0);
  static const chartText = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      textTheme:
          const TextTheme(
            displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ).apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
