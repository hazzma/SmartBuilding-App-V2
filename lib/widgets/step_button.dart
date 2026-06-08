// EDIT_TARGET: lib/widgets/step_button.dart
// EDIT_PURPOSE: Provides plus and minus controls for adjustable numeric values
// EDIT_REASON: Adjustable values such as AC target temperature must use step controls

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StepButton extends StatelessWidget {
  const StepButton({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.unit = '',
  });

  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final canDecrease = value - step >= min;
    final canIncrease = value + step <= max;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Decrease',
            onPressed: canDecrease ? () => onChanged(value - step) : null,
            color: AppColors.primary,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: Text(
              '$value$unit',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Increase',
            onPressed: canIncrease ? () => onChanged(value + step) : null,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
