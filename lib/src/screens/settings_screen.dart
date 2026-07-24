import 'package:flutter/material.dart';

import '../models/mqtt_connection_config.dart';
import '../state/smart_building_controller.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/page_scaffold.dart';

// EDIT_TARGET: settings_screen.dart
// EDIT_PURPOSE: Menampilkan konfigurasi global broker, topic, koneksi MQTT, dan app behavior.
// EDIT_REASON: FSD update memindahkan Broker Setup / Connection ke Settings.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});

  final SmartBuildingController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    _syncFromConfig();
    final config = widget.controller.config;
    return PageScaffold(
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'MQTT Connection',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  widget.controller.isConnected
                      ? AppBadge.online('Connected')
                      : AppBadge.offline('Offline'),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: host,
                decoration: const InputDecoration(labelText: 'Broker Host'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: port,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Broker Port'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: username,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stateTopic,
                decoration: const InputDecoration(labelText: 'State Topic'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commandTopic,
                decoration: const InputDecoration(
                  labelText: 'Command Topic Template',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: publishInterval,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Publish Interval Seconds',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Settings'),
                  ),
                  FilledButton.icon(
                    onPressed: widget.controller.isConnecting
                        ? null
                        : () async {
                            await _saveSettings();
                            await widget.controller.connect();
                          },
                    icon: widget.controller.isConnecting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: Text(
                      widget.controller.isConnecting ? 'Connecting' : 'Connect',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.controller.isConnected
                        ? widget.controller.disconnect
                        : null,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _restoreDefaultTopics,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restore Defaults'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.controller.injectSampleState,
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Inject Sample'),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Behavior',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _Line(label: 'State Topic', value: config.stateTopic),
              _Line(label: 'Command Topic', value: config.commandTopicTemplate),
              _Line(
                label: 'Stale Threshold',
                value: '${config.staleAfter.inSeconds} seconds',
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('Light mode - Inter/Roboto fallback - FSD palette'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    final controller = widget.controller;
    await controller.updateConfig(
      controller.config.copyWith(
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

  Future<void> _restoreDefaultTopics() async {
    stateTopic.text = 'smart-building/master/+/state';
    commandTopic.text = 'smart-building/master/{master}/command';
    publishInterval.text = '10';
    await _saveSettings();
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

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label)),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
