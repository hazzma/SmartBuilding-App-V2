import 'package:flutter/material.dart';

// EDIT_TARGET: page_scaffold.dart
// EDIT_PURPOSE: Menyediakan padding dan scroll default untuk setiap halaman.
// EDIT_REASON: Screen FSD membutuhkan layout konsisten, scan-friendly, dan tidak tumpang tindih.
class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
