// EDIT_TARGET: control_state.dart
// EDIT_PURPOSE: Represents controllable device state for a classroom.
// EDIT_REASON: FSD V2 separates device power state from UI controls and automation.

class ControlState {
  const ControlState({
    this.acPower,
    this.acTargetTemp,
    this.projectorPower,
    this.lampChannels = const <LightChannelState>[],
  });

  final bool? acPower;
  final int? acTargetTemp;
  final bool? projectorPower;
  final List<LightChannelState> lampChannels;

  Map<String, dynamic> toJson() {
    return {
      'acPower': acPower,
      'acTargetTemp': acTargetTemp,
      'projectorPower': projectorPower,
      'lampChannels': lampChannels.map((item) => item.toJson()).toList(),
    };
  }

  factory ControlState.fromJson(Map<String, dynamic> json) {
    return ControlState(
      acPower: json['acPower'] as bool?,
      acTargetTemp: json['acTargetTemp'] as int?,
      projectorPower: json['projectorPower'] as bool?,
      lampChannels: (json['lampChannels'] as List<dynamic>? ?? const [])
          .map(
            (item) => LightChannelState.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class LightChannelState {
  const LightChannelState({required this.id, required this.name, this.power})
      : assert(id >= 1 && id <= 4, 'Light channel id must be between 1 and 4');

  final int id;
  final String name;
  final bool? power;

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'power': power};
  }

  factory LightChannelState.fromJson(Map<String, dynamic> json) {
    return LightChannelState(
      id: json['id'] as int? ?? 1,
      name: json['name'] as String? ?? 'Lamp',
      power: json['power'] as bool?,
    );
  }
}
