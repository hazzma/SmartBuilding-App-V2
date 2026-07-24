import 'package:flutter/material.dart';

import '../models/master_state.dart';
import '../state/smart_building_controller.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/sensor_card.dart';
import '../widgets/sensor_graph.dart';

// EDIT_TARGET: master_dashboard_screen.dart
// EDIT_PURPOSE: Menampilkan dashboard active master dengan sensor dan ringkasan kontrol.
// EDIT_REASON: FSD meminta dashboard fokus pada selected master dan latest state.
class MasterDashboardScreen extends StatelessWidget {
  const MasterDashboardScreen({super.key, required this.controller});

  final SmartBuildingController controller;

  @override
  Widget build(BuildContext context) {
    final master = controller.activeMaster;
    if (master == null) {
      return PageScaffold(
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.dashboard_customize_outlined, size: 42),
                const SizedBox(height: 8),
                Text(
                  'Select a master to open dashboard',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => controller.changeTab(2),
                  icon: const Icon(Icons.view_list),
                  label: const Text('Open Master List'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return PageScaffold(
      children: [
        _ActiveHeader(master: master, stale: _isStale(master)),
        _SensorGrid(master: master),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temperature Trend',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SensorGraph(points: master.sensorData.temperaturePointsC),
            ],
          ),
        ),
        _ControlSummary(master: master),
      ],
    );
  }

  bool _isStale(MasterState master) {
    final item = controller.masters
        .where((entry) => entry.state.identityKey == master.identityKey)
        .firstOrNull;
    return item?.isStale(DateTime.now()) ?? false;
  }
}

class _ActiveHeader extends StatelessWidget {
  const _ActiveHeader({required this.master, required this.stale});

  final MasterState master;
  final bool stale;

  @override
  Widget build(BuildContext context) {
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
                  master.deviceName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'Firmware ${master.firmwareVersion} • ${master.identityKey}',
                ),
              ],
            ),
          ),
          stale ? AppBadge.warning('Stale') : AppBadge.online('Online'),
        ],
      ),
    );
  }
}

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({required this.master});

  final MasterState master;

  @override
  Widget build(BuildContext context) {
    final data = master.sensorData;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 720;
        final cards = [
          SensorCard(
            title: 'Average Temperature',
            value: data.temperatureAverageC == null
                ? '-'
                : '${data.temperatureAverageC!.toStringAsFixed(1)} C',
            icon: Icons.thermostat,
          ),
          SensorCard(
            title: 'CO2',
            value: data.co2Ppm == null ? '-' : '${data.co2Ppm!.round()} ppm',
            icon: Icons.co2,
          ),
          SensorCard(
            title: 'Lux',
            value: data.lux == null ? '-' : '${data.lux!.round()} lx',
            icon: Icons.light_mode_outlined,
          ),
          SensorCard(
            title: 'Human Presence',
            value: switch (data.humanPresence) {
              true => 'Present',
              false => 'Not Present',
              null => 'Unknown',
            },
            icon: Icons.sensor_occupied_outlined,
            badge: switch (data.humanPresence) {
              true => AppBadge.online('Present'),
              false => AppBadge.offline('Clear'),
              null => AppBadge.warning('Unknown'),
            },
          ),
        ];

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

class _ControlSummary extends StatelessWidget {
  const _ControlSummary({required this.master});

  final MasterState master;

  @override
  Widget build(BuildContext context) {
    final controls = master.controls;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Control Summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (controls.ac.available)
                AppBadge.debug(
                  'AC ${controls.ac.power == true ? 'On' : 'Off'}'
                  '${controls.ac.targetTemperatureC == null ? '' : ' ${controls.ac.targetTemperatureC!.round()} C'}',
                ),
              if (controls.projector.available)
                AppBadge.debug(
                  'Projector ${controls.projector.power == true ? 'On' : 'Off'}',
                ),
              if (controls.lights.available)
                for (final channel in controls.lights.channels)
                  channel.power
                      ? AppBadge.online('${channel.name} On')
                      : AppBadge.offline('${channel.name} Off'),
              AppBadge.debug(
                '${master.onlineSlaveCount}/${master.slaves.length} slaves online',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
