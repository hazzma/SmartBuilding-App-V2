import 'package:flutter/material.dart';

import '../models/master_registry_item.dart';
import '../state/smart_building_controller.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/sensor_graph.dart';

// EDIT_TARGET: master_list_screen.dart
// EDIT_PURPOSE: Menampilkan registry master dari wildcard state subscription.
// EDIT_REASON: User harus bisa melihat semua master dan memilih satu active master.
class MasterListScreen extends StatelessWidget {
  const MasterListScreen({super.key, required this.controller});

  final SmartBuildingController controller;

  @override
  Widget build(BuildContext context) {
    final masters = controller.masters;
    if (masters.isEmpty) {
      return PageScaffold(
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.hub_outlined, size: 42),
                const SizedBox(height: 8),
                Text(
                  'No master state received yet',
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
          ),
        ],
      );
    }

    return PageScaffold(
      children: [
        Text('Master List', style: Theme.of(context).textTheme.headlineSmall),
        for (final item in masters)
          _MasterCard(controller: controller, item: item),
      ],
    );
  }
}

class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.controller, required this.item});

  final SmartBuildingController controller;
  final MasterRegistryItem item;

  @override
  Widget build(BuildContext context) {
    final state = item.state;
    final stale = item.isStale(DateTime.now());
    final selected = controller.activeMasterKey == state.identityKey;

    return AppCard(
      onTap: () => controller.selectMaster(state.identityKey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.deviceName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (selected) AppBadge.debug('Active'),
              const SizedBox(width: 8),
              stale ? AppBadge.warning('Stale') : AppBadge.online('Online'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Firmware ${state.firmwareVersion} • ${state.identityKey}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallStatus(label: 'WiFi', value: state.network.wifiOnline),
              _SmallStatus(label: 'LAN', value: state.network.lanOnline),
              _SmallStatus(label: 'RS485', value: state.network.rs485Online),
              AppBadge.debug('${state.slaves.length} slaves'),
            ],
          ),
          const SizedBox(height: 12),
          SensorGraph(
            points: state.sensorData.temperaturePointsC,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _SmallStatus extends StatelessWidget {
  const _SmallStatus({required this.label, required this.value});

  final String label;
  final bool? value;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      true => AppBadge.online(label),
      false => AppBadge.offline(label),
      null => AppBadge.warning(label),
    };
  }
}
