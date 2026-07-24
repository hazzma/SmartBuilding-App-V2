import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// EDIT_TARGET: app_badge.dart
// EDIT_PURPOSE: Membuat reusable status badge untuk online, warning, error, debug.
// EDIT_REASON: FSD memakai badge status berulang di master card, dashboard, dan detail.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  factory AppBadge.online(String label) =>
      AppBadge(label: label, color: AppColors.success);

  factory AppBadge.warning(String label) =>
      AppBadge(label: label, color: AppColors.warning);

  factory AppBadge.error(String label) =>
      AppBadge(label: label, color: AppColors.error);

  factory AppBadge.offline(String label) =>
      AppBadge(label: label, color: AppColors.offline);

  factory AppBadge.debug(String label) =>
      AppBadge(label: label, color: AppColors.debug);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
