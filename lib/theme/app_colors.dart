// EDIT_TARGET: lib/theme/app_colors.dart
// EDIT_PURPOSE: Defines the Smart Building App color tokens from FSD Section 5
// EDIT_REASON: Centralized color constants keep visual styling consistent across widgets and screens

import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Main action color for primary buttons, active navigation, and focused input borders.
  static const Color primary = Color(0xFF2563EB);

  // Darker primary color for stronger primary states such as pressed/active containers.
  static const Color primaryDark = Color(0xFF1D4ED8);

  // Accent color for secondary highlights, sensor accents, and connection-related UI.
  static const Color secondary = Color(0xFF14B8A6);

  // Main app page background behind screens and dashboards.
  static const Color background = Color(0xFFF8FAFC);

  // Default surface color for cards, modals, inputs, AppBar background, and button text on colored buttons.
  static const Color surface = Color(0xFFFFFFFF);

  // Softer surface color for inactive sections, selected containers, and subtle background blocks.
  static const Color surfaceSoft = Color(0xFFF1F5F9);

  // Main text color for titles, labels, and primary readable content.
  static const Color textPrimary = Color(0xFF0F172A);

  // Secondary text color for subtitles, captions, hints, and less important metadata.
  static const Color textSecondary = Color(0xFF64748B);

  // Border color for cards, dividers, input outlines, and light separators.
  static const Color border = Color(0xFFCBD5E1);

  // Success/ON color for connected state, online badges, and powered-on device buttons.
  static const Color success = Color(0xFF22C55E);

  // Warning color for unstable state, attention badges, and caution messages.
  static const Color warning = Color(0xFFF59E0B);

  // Error/OFF color for failed state, critical disconnected state, delete actions, and powered-off buttons.
  static const Color error = Color(0xFFEF4444);

  // Offline/disabled color for unknown device state, unavailable controls, and inactive UI.
  static const Color offline = Color(0xFF94A3B8);

  // Main line color for sensor graph charts.
  static const Color chartLine = Color(0xFF2563EB);

  // Secondary line color for an additional sensor series when needed.
  static const Color chartLineSecondary = Color(0xFF14B8A6);

  // Grid and border color inside chart widgets.
  static const Color chartGrid = Color(0xFFE2E8F0);

  // Axis label and chart helper text color.
  static const Color chartText = Color(0xFF64748B);
}
