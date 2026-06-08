// EDIT_TARGET: lib/screens/settings_screen.dart
// EDIT_PURPOSE: Account configuration screen
// EDIT_REASON: Settings keeps account actions separate from classroom operation

import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onSignOut,
  });

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Account'),
        const SizedBox(height: 8),
        AppCard(
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Sign Out',
              icon: Icons.logout,
              onPressed: onSignOut,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.sectionTitle);
  }
}
