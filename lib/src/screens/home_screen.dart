import 'package:flutter/material.dart';

import '../models/device_display_config.dart';
import '../models/master_state.dart';
import '../state/smart_building_controller.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/sensor_card.dart';
import '../widgets/sensor_graph.dart';

// EDIT_TARGET: home_screen.dart
// EDIT_PURPOSE: Membuat Home sebagai dashboard room/class utama dengan sensor dan kontrol.
// EDIT_REASON: FSD update menyederhanakan UX sehingga user biasa hanya masuk Home.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final SmartBuildingController controller;

  @override
  Widget build(BuildContext context) {
    final masters = controller.homeMasters;
    final active = controller.activeMaster;
    final activeVisible =
        active != null &&
        masters.any((item) => item.state.identityKey == active.identityKey);

    if (masters.isEmpty) {
      return PageScaffold(
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.meeting_room_outlined, size: 42),
                const SizedBox(height: 8),
                Text(
                  'No active room selected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => controller.changeTab(1),
                  icon: const Icon(Icons.devices_other),
                  label: const Text('Go to Devices'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final selectedMaster = activeVisible ? active : masters.first.state;
    if (!activeVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selectMaster(selectedMaster.identityKey);
      });
    }
    final deviceConfig = controller.deviceConfigFor(selectedMaster.identityKey);

    return PageScaffold(
      children: [
        _RoomSelector(
          controller: controller,
          masters: masters.map((item) => item.state).toList(growable: false),
          selected: selectedMaster,
        ),
        _RoomHeader(
          controller: controller,
          master: selectedMaster,
          config: deviceConfig,
        ),
        _SensorSummary(master: selectedMaster, config: deviceConfig),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sensor Trend',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SensorGraph(points: selectedMaster.sensorData.temperaturePointsC),
            ],
          ),
        ),
        _HomeControls(
          controller: controller,
          master: selectedMaster,
          config: deviceConfig,
        ),
      ],
    );
  }
}

class _RoomSelector extends StatelessWidget {
  const _RoomSelector({
    required this.controller,
    required this.masters,
    required this.selected,
  });

  final SmartBuildingController controller;
  final List<MasterState> masters;
  final MasterState selected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: DropdownButtonFormField<String>(
        initialValue: selected.identityKey,
        decoration: const InputDecoration(labelText: 'Room / Class'),
        items: [
          for (final master in masters)
            DropdownMenuItem(
              value: master.identityKey,
              child: Text(controller.roomLabelFor(master)),
            ),
        ],
        onChanged: (value) {
          if (value != null) controller.selectMaster(value);
        },
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({
    required this.controller,
    required this.master,
    required this.config,
  });

  final SmartBuildingController controller;
  final MasterState master;
  final DeviceDisplayConfig config;

  @override
  Widget build(BuildContext context) {
    final stale = controller.activeMasterIsStale;
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.apartment, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.nameFor(master.deviceName),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${master.deviceName} - Firmware ${master.firmwareVersion}',
                ),
              ],
            ),
          ),
          controller.isConnected
              ? stale
                    ? AppBadge.warning('Stale')
                    : AppBadge.online('Online')
              : AppBadge.offline('MQTT Offline'),
        ],
      ),
    );
  }
}

class _SensorSummary extends StatelessWidget {
  const _SensorSummary({required this.master, required this.config});

  final MasterState master;
  final DeviceDisplayConfig config;

  @override
  Widget build(BuildContext context) {
    final data = master.sensorData;
    final cards = <Widget>[
      if (config.enabledSensors.contains(HomeSensor.temperature))
        SensorCard(
          title: 'Temperature',
          value: data.temperatureAverageC == null
              ? '-'
              : '${data.temperatureAverageC!.toStringAsFixed(1)} C',
          icon: Icons.thermostat,
        ),
      if (config.enabledSensors.contains(HomeSensor.co2))
        SensorCard(
          title: 'CO2',
          value: data.co2Ppm == null ? '-' : '${data.co2Ppm!.round()} ppm',
          icon: Icons.co2,
        ),
      if (config.enabledSensors.contains(HomeSensor.lux))
        SensorCard(
          title: 'Lux',
          value: data.lux == null ? '-' : '${data.lux!.round()} lx',
          icon: Icons.light_mode_outlined,
        ),
      if (config.enabledSensors.contains(HomeSensor.presence))
        SensorCard(
          title: 'Presence',
          value: switch (data.humanPresence) {
            true => 'Present',
            false => 'Not Present',
            null => 'Unknown',
          },
          icon: Icons.sensor_occupied_outlined,
        ),
    ];

    if (cards.isEmpty) {
      return const AppCard(child: Text('No sensor info enabled for this room'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 720;
        return GridView.count(
          crossAxisCount: wide ? 4 : 2,
          childAspectRatio: wide ? 1.45 : 1.18,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }
}

class _HomeControls extends StatelessWidget {
  const _HomeControls({
    required this.controller,
    required this.master,
    required this.config,
  });

  final SmartBuildingController controller;
  final MasterState master;
  final DeviceDisplayConfig config;

  @override
  Widget build(BuildContext context) {
    final controls = master.controls;
    final canSend = controller.canPublishControls;
    final hasAnyControl = config.enabledControls.isNotEmpty;

    if (!hasAnyControl) {
      return const AppCard(child: Text('No controls enabled for this room'));
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Control Panel', style: Theme.of(context).textTheme.titleMedium),
          if (!canSend) ...[
            const SizedBox(height: 8),
            const Text(
              'Controls are disabled until MQTT is connected and master is fresh.',
            ),
          ],
          if (config.enabledControls.contains(HomeControl.ac) &&
              controls.ac.available)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                controls.ac.targetTemperatureC == null
                    ? 'AC'
                    : 'AC - ${controls.ac.targetTemperatureC!.round()} C',
              ),
              value: controls.ac.power ?? false,
              onChanged: canSend
                  ? (value) => controller.sendAcCommand(
                      value,
                      controls.ac.targetTemperatureC,
                    )
                  : null,
            ),
          if (config.enabledControls.contains(HomeControl.projector) &&
              controls.projector.available)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Projector'),
              value: controls.projector.power ?? false,
              onChanged: canSend ? controller.sendProjectorCommand : null,
            ),
          if (config.enabledControls.contains(HomeControl.lights) &&
              controls.lights.available)
            for (final channel in controls.lights.channels)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(channel.name),
                subtitle: Text('Lamp ${channel.id}'),
                value: channel.power,
                onChanged: canSend
                    ? (value) => controller.sendLampCommand(channel.id, value)
                    : null,
              ),
        ],
      ),
    );
  }
}
