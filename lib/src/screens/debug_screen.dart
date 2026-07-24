import 'package:flutter/material.dart';

import '../models/debug_log_entry.dart';
import '../state/smart_building_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/page_scaffold.dart';

// EDIT_TARGET: debug_screen.dart
// EDIT_PURPOSE: Menampilkan log MQTT, raw state, command preview, dan manual command.
// EDIT_REASON: FSD meminta debug detail tidak memenuhi UI utama tapi tetap tersedia.
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key, required this.controller});

  final SmartBuildingController controller;

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final command = TextEditingController();

  @override
  void dispose() {
    command.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final master = controller.activeMaster;
    return PageScaffold(
      children: [
        Text('Debug', style: Theme.of(context).textTheme.headlineSmall),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  controller.isConnected
                      ? AppBadge.online('MQTT Connected')
                      : AppBadge.offline('MQTT Offline'),
                  AppBadge.debug('State ${controller.config.stateTopic}'),
                  if (master != null)
                    AppBadge.debug(
                      'Command ${controller.config.commandTopicFor(master.identityKey)}',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: command,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Manual Command JSON',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => controller.publishManualCommand(command.text),
                icon: const Icon(Icons.send),
                label: const Text('Publish Manual Command'),
              ),
            ],
          ),
        ),
        _RawPanel(
          title: 'Last Raw State',
          value: controller.lastRawState ?? '-',
        ),
        _RawPanel(
          title: 'Last Sent Command',
          value: controller.lastSentCommand ?? '-',
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MQTT Log', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (controller.debugLog.isEmpty)
                const Text('No debug log yet')
              else
                for (final entry in controller.debugLog.take(40))
                  _LogItem(entry: entry),
            ],
          ),
        ),
      ],
    );
  }
}

class _RawPanel extends StatelessWidget {
  const _RawPanel({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(value),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  const _LogItem({required this.entry});

  final DebugLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.type) {
      DebugLogType.rx => AppColors.secondary,
      DebugLogType.tx => AppColors.primary,
      DebugLogType.error => AppColors.error,
      DebugLogType.info => AppColors.debug,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${entry.type.name.toUpperCase()} • ${entry.timestamp.toIso8601String()}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          SelectableText(entry.message),
        ],
      ),
    );
  }
}
