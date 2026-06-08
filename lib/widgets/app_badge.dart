// EDIT_TARGET: lib/widgets/app_badge.dart
// EDIT_PURPOSE: Provides status badges for connection, warning, and error states
// EDIT_REASON: Status indicators need consistent colors and compact text styling

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppBadgeType { online, offline, warning, error }

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, required this.type});

  final String label;
  final AppBadgeType type;

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _colorForType(AppBadgeType type) {
    return switch (type) {
      AppBadgeType.online => AppColors.success,
      AppBadgeType.offline => AppColors.offline,
      AppBadgeType.warning => AppColors.warning,
      AppBadgeType.error => AppColors.error,
    };
  }
}
