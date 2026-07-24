import 'package:flutter/material.dart';

// EDIT_TARGET: app_card.dart
// EDIT_PURPOSE: Membuat container card reusable dengan padding konsisten.
// EDIT_REASON: FSD menetapkan AppCard sebagai pembungkus konten utama.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: card,
    );
  }
}
