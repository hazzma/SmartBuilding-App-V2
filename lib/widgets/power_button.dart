// EDIT_TARGET: lib/widgets/power_button.dart
// EDIT_PURPOSE: Provides the required power control button for devices
// EDIT_REASON: Lamp, AC, and projector controls need explicit ON/OFF buttons instead of settings switches

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PowerButton extends StatelessWidget {
  const PowerButton({
    super.key,
    required this.isPowered,
    required this.onPressed,
    required this.label,
    this.isLarge = false,
  });

  final bool? isPowered;
  final VoidCallback? onPressed;
  final String label;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final enabled = isPowered != null && onPressed != null;
    final backgroundColor = isPowered == null
        ? AppColors.offline
        : isPowered!
            ? AppColors.success
            : AppColors.error;
    final stateLabel = isPowered == null
        ? 'UNKNOWN'
        : isPowered!
            ? 'ON'
            : 'OFF';

    return SizedBox(
      width: isLarge ? double.infinity : null,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.power_settings_new),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, overflow: TextOverflow.ellipsis),
            Text(
              stateLabel,
              style: AppTextStyles.caption.copyWith(color: AppColors.surface),
            ),
          ],
        ),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.offline,
          disabledForegroundColor: AppColors.surface,
          textStyle: AppTextStyles.bodyMedium,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 22 : 16,
            vertical: isLarge ? 18 : 12,
          ),
        ),
      ),
    );
  }
}
