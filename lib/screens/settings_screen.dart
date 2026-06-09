// EDIT_TARGET: lib/screens/settings_screen.dart
// EDIT_PURPOSE: Account configuration screen
// EDIT_REASON: Settings keeps account actions separate from classroom operation

import 'package:flutter/material.dart';

import '../services/influxdb_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

// NEW UPDATE: INPUT SERVER - START
// EDIT INFLUXDB CARD HERE: color, width, corner radius, padding, and border.
const Color _influxBoxColor = AppColors.surface;
const double _influxBoxMaxWidth = 640;
const double _influxBoxRadius = 8;
const double _influxBoxBorderWidth = 1;
const EdgeInsets _influxBoxPadding = EdgeInsets.all(16);
// NEW UPDATE: INPUT SERVER - END

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.onSignOut,
    // NEW UPDATE: INPUT SERVER - Service and callback for editable InfluxDB settings.
    required this.influxDbService,
    required this.onInfluxDbChanged,
  });

  final Future<void> Function() onSignOut;
  final InfluxDbService influxDbService;
  final ValueChanged<InfluxDbService> onInfluxDbChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // NEW UPDATE: INPUT SERVER - START
  late final _url = TextEditingController(text: widget.influxDbService.url);
  late final _token = TextEditingController(text: widget.influxDbService.token);
  // NEW UPDATE: INPUT SERVER - END

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // NEW UPDATE: INPUT SERVER - START
        const _SectionTitle('InfluxDB'),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _influxBoxMaxWidth),
          child: Container(
            padding: _influxBoxPadding,
            decoration: BoxDecoration(
              // EDIT INFLUXDB CARD COLOR HERE.
              color: _influxBoxColor,
              // EDIT INFLUXDB CARD BORDER COLOR/WIDTH HERE.
              border: Border.all(
                color: AppColors.border,
                width: _influxBoxBorderWidth,
              ),
              // EDIT INFLUXDB CARD CORNER RADIUS HERE.
              borderRadius: BorderRadius.circular(_influxBoxRadius),
            ),
            child: Column(
              children: [
                AppTextInput(label: 'URL', controller: _url),
                const SizedBox(height: 12),
                AppTextInput(
                  label: 'Token',
                  controller: _token,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Save InfluxDB',
                    icon: Icons.save,
                    onPressed: _saveInfluxDb,
                  ),
                ),
              ],
            ),
          ),
        ),
        // NEW UPDATE: INPUT SERVER - END
        const SizedBox(height: 20),
        const _SectionTitle('Account'),
        const SizedBox(height: 8),
        AppCard(
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Sign Out',
              icon: Icons.logout,
              onPressed: widget.onSignOut,
            ),
          ),
        ),
      ],
    );
  }

  // NEW UPDATE: INPUT SERVER - Saves and applies the entered server values.
  void _saveInfluxDb() {
    if ([_url, _token].any((controller) => controller.text.trim().isEmpty)) {
      showAppToast(context, 'All InfluxDB fields are required.');
      return;
    }

    widget.onInfluxDbChanged(
      InfluxDbService(
        url: _url.text.trim(),
        token: _token.text.trim(),
        bucket: widget.influxDbService.bucket,
        measurement: widget.influxDbService.measurement,
      ),
    );
    showAppToast(context, 'InfluxDB settings updated.');
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
