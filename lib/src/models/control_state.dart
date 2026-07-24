// EDIT_TARGET: control_state.dart
// EDIT_PURPOSE: Memetakan state kontrol AC, projector, dan lampu per channel.
// EDIT_REASON: UI hanya boleh menampilkan kontrol yang available dan explicit.
class ControlState {
  const ControlState({
    required this.ac,
    required this.projector,
    required this.lights,
  });

  factory ControlState.fromJson(Map<String, dynamic>? json) {
    return ControlState(
      ac: AcControlState.fromJson(_readMap(json?['ac'])),
      projector: ProjectorControlState.fromJson(_readMap(json?['projector'])),
      lights: LightsControlState.fromJson(_readMap(json?['lights'])),
    );
  }

  final AcControlState ac;
  final ProjectorControlState projector;
  final LightsControlState lights;

  static Map<String, dynamic>? _readMap(Object? value) {
    return value is Map<String, dynamic> ? value : null;
  }
}

class AcControlState {
  const AcControlState({
    required this.available,
    required this.power,
    required this.targetTemperatureC,
  });

  factory AcControlState.fromJson(Map<String, dynamic>? json) {
    return AcControlState(
      available: json?['available'] == true,
      power: _readBool(json?['power'] ?? json?['on']),
      targetTemperatureC: _readDouble(
        json?['target_temperature_c'] ?? json?['target_temp_c'],
      ),
    );
  }

  final bool available;
  final bool? power;
  final double? targetTemperatureC;
}

class ProjectorControlState {
  const ProjectorControlState({required this.available, required this.power});

  factory ProjectorControlState.fromJson(Map<String, dynamic>? json) {
    return ProjectorControlState(
      available: json?['available'] == true,
      power: _readBool(json?['power'] ?? json?['on']),
    );
  }

  final bool available;
  final bool? power;
}

class LightsControlState {
  const LightsControlState({required this.available, required this.channels});

  factory LightsControlState.fromJson(Map<String, dynamic>? json) {
    final rawChannels = json?['channels'];
    final channels = rawChannels is List
        ? rawChannels
              .whereType<Map<String, dynamic>>()
              .map(LightChannelState.fromJson)
              .where((channel) => channel.id >= 1 && channel.id <= 4)
              .toList(growable: false)
        : <LightChannelState>[];

    return LightsControlState(
      available: json?['available'] == true,
      channels: channels,
    );
  }

  final bool available;
  final List<LightChannelState> channels;
}

class LightChannelState {
  const LightChannelState({
    required this.id,
    required this.name,
    required this.power,
  });

  factory LightChannelState.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return LightChannelState(
      id: id is num ? id.toInt() : int.tryParse('$id') ?? 0,
      name: json['name']?.toString() ?? 'Lamp $id',
      power: _readBool(json['power'] ?? json['on']) ?? false,
    );
  }

  final int id;
  final String name;
  final bool power;
}

bool? _readBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return null;
}

double? _readDouble(Object? value) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
