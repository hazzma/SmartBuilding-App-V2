import 'package:flutter/material.dart';

import 'app_badge.dart';
import 'app_card.dart';

// EDIT_TARGET: sensor_card.dart
// EDIT_PURPOSE: Menampilkan nilai sensor utama dalam card ringkas.
// EDIT_REASON: Dashboard wajib menampilkan temperature, CO2, lux, dan presence secara jelas.
class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.badge,
  });

  final String title;
  final String value;
  final IconData icon;
  final AppBadge? badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.displaySmall),
        ],
      ),
    );
  }
}
