import 'package:flutter/material.dart';

import '../models/debug_log_entry.dart';
import '../models/device_display_config.dart';
import '../models/master_registry_item.dart';
import '../models/master_state.dart';
import '../state/smart_building_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/status_row.dart';

// EDIT_TARGET: devices_screen.dart
// EDIT_PURPOSE: Membuat Devices sebagai discovery dan konfigurasi tampilan per master/room.
// EDIT_REASON: FSD update memindahkan Master List, Detail, dan Debug ke Devices advanced.
class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key, required this.controller});

  final SmartBuildingController controller;

  @override
  Widget build(BuildContext context) {
    final masters = controller.masters;
    final active = controller.activeMaster;

    return PageScaffold(
      children: [
        Text('Devices', style: Theme.of(context).textTheme.headlineSmall),
        if (masters.isEmpty)
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.hub_outlined, size: 42),
                const SizedBox(height: 8),
                Text(
                  'No master discovered yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: controller.injectSampleState,
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Inject Sample State'),
                ),
              ],
            ),
          )
        else
          for (final item in masters)
            _DeviceDiscoveryCard(controller: controller, item: item),
        if (active != null)
          _DeviceConfigPanel(controller: controller, master: active),
      ],
    );
  }
}

class _DeviceDiscoveryCard extends StatelessWidget {
  const _DeviceDiscoveryCard({required this.controller, required this.item});

  final SmartBuildingController controller;
  final MasterRegistryItem item;

  @override
  Widget build(BuildContext context) {
    final state = item.state;
    final config = controller.deviceConfigFor(state.identityKey);
    final selected = controller.activeMasterKey == state.identityKey;
    final stale = item.isStale(DateTime.now());

    return AppCard(
      onTap: () => controller.selectMaster(state.identityKey),
      child: Row(
        children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.nameFor(state.deviceName),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${state.identityKey} - ${state.slaves.length} slaves'),
              ],
            ),
          ),
          config.showInHome
              ? AppBadge.online('Home')
              : AppBadge.offline('Hidden'),
          const SizedBox(width: 8),
          stale ? AppBadge.warning('Stale') : AppBadge.online('Fresh'),
        ],
      ),
    );
  }
}

class _DeviceConfigPanel extends StatefulWidget {
  const _DeviceConfigPanel({required this.controller, required this.master});

  final SmartBuildingController controller;
  final MasterState master;

  @override
  State<_DeviceConfigPanel> createState() => _DeviceConfigPanelState();
}

class _DeviceConfigPanelState extends State<_DeviceConfigPanel> {
  late final TextEditingController displayName;
  late final TextEditingController roomName;
  String identityKey = '';

  @override
  void initState() {
    super.initState();
    displayName = TextEditingController();
    roomName = TextEditingController();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _DeviceConfigPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.master.identityKey != widget.master.identityKey) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    displayName.dispose();
    roomName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final master = widget.master;
    final config = widget.controller.deviceConfigFor(master.identityKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Device Config',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show in Home'),
                value: config.showInHome,
                onChanged: (value) => _save(config.copyWith(showInHome: value)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: displayName,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: roomName,
                decoration: const InputDecoration(
                  labelText: 'Room / Class Name',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _save(
                  config.copyWith(
                    displayName: displayName.text.trim(),
                    roomName: roomName.text.trim(),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text('Save Names'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _VisibilityPanel(config: config, onChanged: _save),
        const SizedBox(height: 12),
        _AdvancedPanel(controller: widget.controller, master: master),
        const SizedBox(height: 12),
        if (config.debugEnabled)
          _DebugAdvancedPanel(controller: widget.controller)
        else
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Advanced Debug'),
              subtitle: const Text('Enable to show raw JSON and MQTT logs'),
              value: false,
              onChanged: (value) => _save(config.copyWith(debugEnabled: value)),
            ),
          ),
      ],
    );
  }

  void _syncControllers() {
    identityKey = widget.master.identityKey;
    final config = widget.controller.deviceConfigFor(identityKey);
    displayName.text = config.displayName;
    roomName.text = config.roomName;
  }

  Future<void> _save(DeviceDisplayConfig config) async {
    await widget.controller.updateDeviceConfig(
      widget.master.identityKey,
      config,
    );
  }
}

class _VisibilityPanel extends StatelessWidget {
  const _VisibilityPanel({required this.config, required this.onChanged});

  final DeviceDisplayConfig config;
  final ValueChanged<DeviceDisplayConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Home Visibility',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Sensors', style: Theme.of(context).textTheme.titleSmall),
          for (final sensor in HomeSensor.values)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(sensor.name),
              value: config.enabledSensors.contains(sensor),
              onChanged: (value) {
                final sensors = {...config.enabledSensors};
                value == true ? sensors.add(sensor) : sensors.remove(sensor);
                onChanged(config.copyWith(enabledSensors: sensors));
              },
            ),
          const Divider(),
          Text('Controls', style: Theme.of(context).textTheme.titleSmall),
          for (final control in HomeControl.values)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(control.name),
              value: config.enabledControls.contains(control),
              onChanged: (value) {
                final controls = {...config.enabledControls};
                value == true
                    ? controls.add(control)
                    : controls.remove(control);
                onChanged(config.copyWith(enabledControls: controls));
              },
            ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Advanced Debug'),
            value: config.debugEnabled,
            onChanged: (value) =>
                onChanged(config.copyWith(debugEnabled: value)),
          ),
        ],
      ),
    );
  }
}

class _AdvancedPanel extends StatelessWidget {
  const _AdvancedPanel({required this.controller, required this.master});

  final SmartBuildingController controller;
  final MasterState master;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Master Detail Advanced',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          _Line(label: 'Device ID', value: master.deviceId ?? '-'),
          _Line(label: 'Device Name', value: master.deviceName),
          _Line(label: 'Master MAC', value: master.masterMac ?? '-'),
          _Line(label: 'Firmware', value: master.firmwareVersion),
          const SizedBox(height: 8),
          StatusRow(
            icon: Icons.wifi,
            label: 'WiFi',
            value: master.network.wifiOnline,
          ),
          const SizedBox(height: 8),
          StatusRow(
            icon: Icons.lan,
            label: 'LAN',
            value: master.network.lanOnline,
          ),
          const SizedBox(height: 8),
          StatusRow(
            icon: Icons.settings_input_component,
            label: 'RS485',
            value: master.network.rs485Online,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: AppBadge.debug(
              '${master.onlineSlaveCount}/${master.slaves.length} slaves online',
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugAdvancedPanel extends StatelessWidget {
  const _DebugAdvancedPanel({required this.controller});

  final SmartBuildingController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Debug',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText('Last State:\n${controller.lastRawState ?? '-'}'),
          const SizedBox(height: 8),
          SelectableText('Last Command:\n${controller.lastSentCommand ?? '-'}'),
          const Divider(),
          for (final entry in controller.debugLog.take(12))
            _DebugLogItem(entry: entry),
        ],
      ),
    );
  }
}

class _DebugLogItem extends StatelessWidget {
  const _DebugLogItem({required this.entry});

  final DebugLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.type) {
      DebugLogType.rx => AppColors.secondary,
      DebugLogType.tx => AppColors.primary,
      DebugLogType.error => AppColors.error,
      DebugLogType.info => AppColors.debug,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SelectableText(
        '${entry.type.name.toUpperCase()} - ${entry.message}',
        style: TextStyle(color: color),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
