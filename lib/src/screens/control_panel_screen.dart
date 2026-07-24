import 'package:flutter/material.dart';

import '../models/control_state.dart';
import '../state/smart_building_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/page_scaffold.dart';

// EDIT_TARGET: control_panel_screen.dart
// EDIT_PURPOSE: Menampilkan kontrol AC, projector, dan lampu channel active master.
// EDIT_REASON: FSD mewajibkan kontrol hanya muncul jika available dan command final-state.
class ControlPanelScreen extends StatelessWidget {
  const ControlPanelScreen({super.key, required this.controller});

  final SmartBuildingController controller;

  @override
  Widget build(BuildContext context) {
    final master = controller.activeMaster;
    if (master == null) {
      return PageScaffold(
        children: [
          AppCard(
            child: Text(
              'No active master selected',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      );
    }

    final controls = master.controls;
    final canSend = controller.canPublishControls;
    return PageScaffold(
      children: [
        Text('Control Panel', style: Theme.of(context).textTheme.headlineSmall),
        if (!canSend)
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.isConnected
                        ? 'Controls are locked because selected master is stale'
                        : 'Controls are locked because MQTT is offline',
                  ),
                ),
              ],
            ),
          ),
        if (controls.ac.available)
          _AcControl(
            ac: controls.ac,
            enabled: canSend,
            onSend: controller.sendAcCommand,
          ),
        if (controls.projector.available)
          _ProjectorControl(
            projector: controls.projector,
            enabled: canSend,
            onSend: controller.sendProjectorCommand,
          ),
        if (controls.lights.available)
          _LampControls(
            lights: controls.lights,
            enabled: canSend,
            onLamp: controller.sendLampCommand,
            onAll: controller.sendAllLampCommand,
          ),
        if (!controls.ac.available &&
            !controls.projector.available &&
            !controls.lights.available)
          const AppCard(child: Text('No available controls in latest state')),
      ],
    );
  }
}

class _AcControl extends StatefulWidget {
  const _AcControl({
    required this.ac,
    required this.enabled,
    required this.onSend,
  });

  final AcControlState ac;
  final bool enabled;
  final void Function(bool power, double? targetTemperatureC) onSend;

  @override
  State<_AcControl> createState() => _AcControlState();
}

class _AcControlState extends State<_AcControl> {
  late bool power;
  late double target;

  @override
  void initState() {
    super.initState();
    power = widget.ac.power ?? false;
    target = widget.ac.targetTemperatureC ?? 24;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AC', style: Theme.of(context).textTheme.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Power'),
            value: power,
            onChanged: widget.enabled
                ? (value) {
                    setState(() => power = value);
                    widget.onSend(power, target);
                  }
                : null,
          ),
          Row(
            children: [
              const Text('Target'),
              Expanded(
                child: Slider(
                  value: target,
                  min: 16,
                  max: 30,
                  divisions: 14,
                  label: '${target.round()} C',
                  onChanged: widget.enabled
                      ? (value) => setState(() => target = value)
                      : null,
                  onChangeEnd: widget.enabled
                      ? (value) => widget.onSend(power, value)
                      : null,
                ),
              ),
              SizedBox(width: 48, child: Text('${target.round()} C')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectorControl extends StatelessWidget {
  const _ProjectorControl({
    required this.projector,
    required this.enabled,
    required this.onSend,
  });

  final ProjectorControlState projector;
  final bool enabled;
  final ValueChanged<bool> onSend;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Projector',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: const Text('Explicit power command'),
        value: projector.power ?? false,
        onChanged: enabled ? onSend : null,
      ),
    );
  }
}

class _LampControls extends StatelessWidget {
  const _LampControls({
    required this.lights,
    required this.enabled,
    required this.onLamp,
    required this.onAll,
  });

  final LightsControlState lights;
  final bool enabled;
  final void Function(int channelId, bool power) onLamp;
  final ValueChanged<bool> onAll;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lights', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final channel in lights.channels)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(channel.name),
              subtitle: Text('Channel ${channel.id}'),
              value: channel.power,
              onChanged: enabled ? (value) => onLamp(channel.id, value) : null,
            ),
          const Divider(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: enabled ? () => _confirmAll(context, true) : null,
                icon: const Icon(Icons.lightbulb),
                label: const Text('All Lamps On'),
              ),
              OutlinedButton.icon(
                onPressed: enabled ? () => _confirmAll(context, false) : null,
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('All Lamps Off'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAll(BuildContext context, bool power) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(power ? 'Turn all lamps on?' : 'Turn all lamps off?'),
        content: const Text('This sends an explicit all-lamps command.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed == true) onAll(power);
  }
}
