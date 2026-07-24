import 'package:flutter/material.dart';

import '../models/mqtt_connection_config.dart';
import '../state/smart_building_controller.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/page_scaffold.dart';

// EDIT_TARGET: broker_setup_screen.dart
// EDIT_PURPOSE: Membuat screen konfigurasi broker MQTT dan connect/disconnect.
// EDIT_REASON: FSD first-launch flow dimulai dari Broker Setup / Connection.
class BrokerSetupScreen extends StatefulWidget {
  const BrokerSetupScreen({super.key, required this.controller});

  final SmartBuildingController controller;

  @override
  State<BrokerSetupScreen> createState() => _BrokerSetupScreenState();
}

class _BrokerSetupScreenState extends State<BrokerSetupScreen> {
  late final TextEditingController host;
  late final TextEditingController port;
  late final TextEditingController username;
  late final TextEditingController password;
  late final TextEditingController stateTopic;
  late final TextEditingController commandTopic;
  late final TextEditingController publishInterval;
  String _lastConfigSignature = '';

  @override
  void initState() {
    super.initState();
    final config = widget.controller.config;
    host = TextEditingController(text: config.host);
    port = TextEditingController(text: '${config.port}');
    username = TextEditingController(text: config.username);
    password = TextEditingController(text: config.password);
    stateTopic = TextEditingController(text: config.stateTopic);
    commandTopic = TextEditingController(text: config.commandTopicTemplate);
    publishInterval = TextEditingController(
      text: '${config.publishIntervalSeconds}',
    );
    _lastConfigSignature = _signature(config);
  }

  @override
  void dispose() {
    host.dispose();
    port.dispose();
    username.dispose();
    password.dispose();
    stateTopic.dispose();
    commandTopic.dispose();
    publishInterval.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    _syncFromConfig();
    return PageScaffold(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Broker Setup',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  controller.isConnected
                      ? AppBadge.online('Connected')
                      : AppBadge.offline('Disconnected'),
                ],
              ),
              const SizedBox(height: 16),
              _Field(controller: host, label: 'Host'),
              const SizedBox(height: 12),
              _Field(
                controller: port,
                label: 'Port',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Field(controller: username, label: 'Username'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: password,
                      label: 'Password',
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Field(controller: stateTopic, label: 'State Topic'),
              const SizedBox(height: 12),
              _Field(controller: commandTopic, label: 'Command Topic Template'),
              const SizedBox(height: 12),
              _Field(
                controller: publishInterval,
                label: 'Publish Interval Seconds',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: controller.isConnecting
                        ? null
                        : () async {
                            await _saveConfig();
                            await controller.connect();
                          },
                    icon: controller.isConnecting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: Text(
                      controller.isConnecting ? 'Connecting' : 'Connect',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.isConnected
                        ? controller.disconnect
                        : null,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.injectSampleState,
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Inject Sample State'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveConfig() {
    return widget.controller.updateConfig(
      MqttConnectionConfig(
        host: host.text.trim().isEmpty ? 'localhost' : host.text.trim(),
        port: int.tryParse(port.text) ?? 1883,
        username: username.text.trim(),
        password: password.text,
        stateTopic: stateTopic.text.trim().isEmpty
            ? 'smart-building/master/+/state'
            : stateTopic.text.trim(),
        commandTopicTemplate: commandTopic.text.trim().isEmpty
            ? 'smart-building/master/{master}/command'
            : commandTopic.text.trim(),
        publishIntervalSeconds: int.tryParse(publishInterval.text) ?? 10,
      ),
    );
  }

  void _syncFromConfig() {
    final config = widget.controller.config;
    final nextSignature = _signature(config);
    if (nextSignature == _lastConfigSignature) return;

    host.text = config.host;
    port.text = '${config.port}';
    username.text = config.username;
    password.text = config.password;
    stateTopic.text = config.stateTopic;
    commandTopic.text = config.commandTopicTemplate;
    publishInterval.text = '${config.publishIntervalSeconds}';
    _lastConfigSignature = nextSignature;
  }

  String _signature(MqttConnectionConfig config) {
    return [
      config.host,
      config.port,
      config.username,
      config.password,
      config.stateTopic,
      config.commandTopicTemplate,
      config.publishIntervalSeconds,
    ].join('|');
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label),
    );
  }
}
