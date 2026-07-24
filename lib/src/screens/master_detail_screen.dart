import 'package:flutter/material.dart';

import '../models/master_state.dart';
import '../state/smart_building_controller.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/status_row.dart';

// EDIT_TARGET: master_detail_screen.dart
// EDIT_PURPOSE: Menampilkan detail master, network state, dan slave list.
// EDIT_REASON: FSD meminta Master Detail / Slave List memisahkan informasi teknis dari dashboard.
class MasterDetailScreen extends StatelessWidget {
  const MasterDetailScreen({super.key, required this.controller});

  final SmartBuildingController controller;

  @override
  Widget build(BuildContext context) {
    final master = controller.activeMaster;
    if (master == null) {
      return const PageScaffold(
        children: [AppCard(child: Text('No active master selected'))],
      );
    }

    return PageScaffold(
      children: [
        Text('Master Detail', style: Theme.of(context).textTheme.headlineSmall),
        _IdentityPanel(master: master),
        _NetworkPanel(master: master),
        _SlavePanel(master: master),
      ],
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({required this.master});

  final MasterState master;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            master.deviceName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _Line(label: 'Identity Key', value: master.identityKey),
          _Line(label: 'Device ID', value: master.deviceId ?? '-'),
          _Line(label: 'Master MAC', value: master.masterMac ?? '-'),
          _Line(label: 'Firmware', value: master.firmwareVersion),
          _Line(
            label: 'Last State',
            value: master.receivedAt.toIso8601String(),
          ),
        ],
      ),
    );
  }
}

class _NetworkPanel extends StatelessWidget {
  const _NetworkPanel({required this.master});

  final MasterState master;

  @override
  Widget build(BuildContext context) {
    final network = master.network;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Network', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          StatusRow(icon: Icons.wifi, label: 'WiFi', value: network.wifiOnline),
          const SizedBox(height: 8),
          StatusRow(icon: Icons.lan, label: 'LAN', value: network.lanOnline),
          const SizedBox(height: 8),
          StatusRow(
            icon: Icons.cloud,
            label: 'MQTT',
            value: network.mqttOnline,
          ),
          const SizedBox(height: 8),
          StatusRow(
            icon: Icons.settings_input_component,
            label: 'RS485',
            value: network.rs485Online,
          ),
        ],
      ),
    );
  }
}

class _SlavePanel extends StatelessWidget {
  const _SlavePanel({required this.master});

  final MasterState master;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Slaves',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              AppBadge.debug(
                '${master.onlineSlaveCount}/${master.slaves.length} online',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (master.slaves.isEmpty)
            const Text('No slave data in latest state')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Address')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Capability')),
                  DataColumn(label: Text('Relays')),
                  DataColumn(label: Text('Status')),
                ],
                rows: [
                  for (final slave in master.slaves)
                    DataRow(
                      cells: [
                        DataCell(Text('${slave.address}')),
                        DataCell(Text(slave.name)),
                        DataCell(Text(slave.capability)),
                        DataCell(Text('${slave.relayCount}')),
                        DataCell(
                          slave.online == true
                              ? AppBadge.online('Online')
                              : slave.online == false
                              ? AppBadge.offline('Offline')
                              : AppBadge.warning('Unknown'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
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
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
