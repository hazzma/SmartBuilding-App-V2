import 'package:flutter/material.dart';

import 'app_badge.dart';

// EDIT_TARGET: status_row.dart
// EDIT_PURPOSE: Menampilkan label status dengan ikon dan badge.
// EDIT_REASON: FSD menyatukan status WiFi, LAN, MQTT, RS485, dan stale dalam StatusRow.
class StatusRow extends StatelessWidget {
  const StatusRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final bool? value;

  @override
  Widget build(BuildContext context) {
    final badge = switch (value) {
      true => AppBadge.online('Online'),
      false => AppBadge.offline('Offline'),
      null => AppBadge.warning('Unknown'),
    };

    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        badge,
      ],
    );
  }
}
