import 'dart:convert';

// EDIT_TARGET: master_command.dart
// EDIT_PURPOSE: Membangun JSON command final-state untuk selected master.
// EDIT_REASON: FSD melarang toggle-only command dan mewajibkan command_id unik.
class MasterCommand {
  const MasterCommand({
    required this.target,
    required this.commandId,
    required this.control,
  });

  final String target;
  final String commandId;
  final Map<String, dynamic> control;

  Map<String, dynamic> toJson() {
    return {'target': target, 'command_id': commandId, 'controls': control};
  }

  String encode() => jsonEncode(toJson());

  static MasterCommand lamp({
    required String target,
    required int channelId,
    required bool power,
  }) {
    return MasterCommand(
      target: target,
      commandId: _nextCommandId('lamp-$channelId'),
      control: {
        'lights': {
          'channels': [
            {'id': channelId, 'power': power},
          ],
        },
      },
    );
  }

  static MasterCommand allLamps({required String target, required bool power}) {
    return MasterCommand(
      target: target,
      commandId: _nextCommandId('all-lamps'),
      control: {
        'lights': {
          'all': {'power': power},
        },
      },
    );
  }

  static MasterCommand ac({
    required String target,
    required bool power,
    required double? targetTemperatureC,
  }) {
    return MasterCommand(
      target: target,
      commandId: _nextCommandId('ac'),
      control: {
        'ac': {'power': power, 'target_temperature_c': ?targetTemperatureC},
      },
    );
  }

  static MasterCommand projector({
    required String target,
    required bool power,
  }) {
    return MasterCommand(
      target: target,
      commandId: _nextCommandId('projector'),
      control: {
        'projector': {'power': power},
      },
    );
  }

  static String _nextCommandId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}
