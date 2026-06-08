// EDIT_TARGET: class_automation_config.dart
// EDIT_PURPOSE: Stores classroom automation preferences and defaults.
// EDIT_REASON: FSD V2 defines schedule automation behavior, including projector off by default.

class ClassAutomationConfig {
  const ClassAutomationConfig({
    this.scheduleAutomationEnabled = true,
    this.preStartMinutes = 15,
    this.emptyRoomRecheckMinutes = 5,
    this.autoTurnOnLights = true,
    this.autoTurnOnAc = true,
    this.autoTurnOnProjector = false,
    this.defaultAcTargetTemperature = 24,
  });

  final bool scheduleAutomationEnabled;
  final int preStartMinutes;
  final int emptyRoomRecheckMinutes;
  final bool autoTurnOnLights;
  final bool autoTurnOnAc;
  final bool autoTurnOnProjector;
  final int defaultAcTargetTemperature;

  Map<String, dynamic> toJson() {
    return {
      'scheduleAutomationEnabled': scheduleAutomationEnabled,
      'preStartMinutes': preStartMinutes,
      'emptyRoomRecheckMinutes': emptyRoomRecheckMinutes,
      'autoTurnOnLights': autoTurnOnLights,
      'autoTurnOnAc': autoTurnOnAc,
      'autoTurnOnProjector': autoTurnOnProjector,
      'defaultAcTargetTemperature': defaultAcTargetTemperature,
    };
  }

  factory ClassAutomationConfig.fromJson(Map<String, dynamic> json) {
    return ClassAutomationConfig(
      scheduleAutomationEnabled:
          json['scheduleAutomationEnabled'] as bool? ?? true,
      preStartMinutes: json['preStartMinutes'] as int? ?? 15,
      emptyRoomRecheckMinutes: json['emptyRoomRecheckMinutes'] as int? ?? 5,
      autoTurnOnLights: json['autoTurnOnLights'] as bool? ?? true,
      autoTurnOnAc: json['autoTurnOnAc'] as bool? ?? true,
      autoTurnOnProjector: json['autoTurnOnProjector'] as bool? ?? false,
      defaultAcTargetTemperature:
          json['defaultAcTargetTemperature'] as int? ?? 24,
    );
  }
}
