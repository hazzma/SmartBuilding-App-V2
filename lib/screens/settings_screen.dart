// EDIT_TARGET: lib/screens/settings_screen.dart
// EDIT_PURPOSE: Broker configuration and account options screen
// EDIT_REASON: Allows users to configure connection variables for the EMQX broker and check TLS connection state
import 'package:flutter/material.dart';

import '../services/mqtt_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

const Color _mqttBoxColor = AppColors.surface;
const double _mqttBoxMaxWidth = 640;
const double _mqttBoxRadius = 8;
const double _mqttBoxBorderWidth = 1;
const EdgeInsets _mqttBoxPadding = EdgeInsets.all(16);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.onSignOut,
    required this.mqttService,
  });

  final Future<void> Function() onSignOut;
  final MqttService mqttService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _username;
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    _host = TextEditingController(text: widget.mqttService.host);
    _port = TextEditingController(text: widget.mqttService.port.toString());
    _username = TextEditingController(text: widget.mqttService.username);
    _password = TextEditingController(text: widget.mqttService.password);
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.mqttService.isConnected
        ? AppColors.success
        : (widget.mqttService.isConnecting
            ? AppColors.warning
            : AppColors.error);
    final statusText = widget.mqttService.isConnected
        ? 'Connected'
        : (widget.mqttService.isConnecting
            ? 'Connecting...'
            : 'Disconnected');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('MQTT Connection Setup'),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _mqttBoxMaxWidth),
          child: Container(
            padding: _mqttBoxPadding,
            decoration: BoxDecoration(
              color: _mqttBoxColor,
              border: Border.all(
                color: AppColors.border,
                width: _mqttBoxBorderWidth,
              ),
              borderRadius: BorderRadius.circular(_mqttBoxRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('Status: ', style: AppTextStyles.bodyMedium),
                    Text(
                      statusText,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (!widget.mqttService.isConnected &&
                        !widget.mqttService.isConnecting)
                      TextButton.icon(
                        onPressed: _connectMqtt,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Connect'),
                      )
                    else if (widget.mqttService.isConnected)
                      TextButton.icon(
                        onPressed: _disconnectMqtt,
                        icon: const Icon(Icons.stop),
                        label: const Text('Disconnect',
                            style: TextStyle(color: AppColors.error)),
                      ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                AppTextInput(label: 'Broker Host', controller: _host),
                const SizedBox(height: 12),
                AppTextInput(label: 'Port (TLS/SSL)', controller: _port),
                const SizedBox(height: 12),
                AppTextInput(label: 'Username', controller: _username),
                const SizedBox(height: 12),
                AppTextInput(
                  label: 'Password',
                  controller: _password,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Save Configuration',
                    icon: Icons.save,
                    onPressed: _saveMqttSettings,
                  ),
                ),
              ],
            ),
          ),
        ),
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

  void _saveMqttSettings() async {
    final parsedPort = int.tryParse(_port.text.trim());
    if (parsedPort == null) {
      showAppToast(context, 'Port must be a valid integer.');
      return;
    }

    if (_host.text.trim().isEmpty) {
      showAppToast(context, 'Host is required.');
      return;
    }

    await widget.mqttService.saveSettings(
      host: _host.text.trim(),
      port: parsedPort,
      username: _username.text.trim(),
      password: _password.text.trim(),
    );

    showAppToast(context, 'MQTT configuration saved.');
    _connectMqtt();
  }

  void _connectMqtt() async {
    try {
      await widget.mqttService.connect();
      if (mounted) {
        showAppToast(context, 'MQTT Connection active.');
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Connection failed: $e');
      }
    }
  }

  void _disconnectMqtt() async {
    await widget.mqttService.disconnect();
    if (mounted) {
      showAppToast(context, 'MQTT disconnected.');
    }
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
