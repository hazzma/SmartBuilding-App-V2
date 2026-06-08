// EDIT_TARGET: lib/theme/app_text_styles.dart
// EDIT_PURPOSE: Defines typography tokens from FSD Section 6
// EDIT_REASON: Shared text styles keep font sizing and weights consistent across the app

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const List<String> _fontFallback = ['Roboto'];

  static const TextStyle displayTitle = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle pageTitle = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
