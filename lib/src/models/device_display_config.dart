// EDIT_TARGET: device_display_config.dart
// EDIT_PURPOSE: Menyimpan konfigurasi tampilan master/room untuk Home.
// EDIT_REASON: FSD update meminta Devices mengatur showInHome, nama room, sensor, control, dan debug.
class DeviceDisplayConfig {
  const DeviceDisplayConfig({
    this.showInHome = true,
    this.displayName = '',
    this.roomName = '',
    this.enabledSensors = const {
      HomeSensor.temperature,
      HomeSensor.co2,
      HomeSensor.lux,
      HomeSensor.presence,
    },
    this.enabledControls = const {
      HomeControl.ac,
      HomeControl.projector,
      HomeControl.lights,
    },
    this.debugEnabled = false,
  });

  final bool showInHome;
  final String displayName;
  final String roomName;
  final Set<HomeSensor> enabledSensors;
  final Set<HomeControl> enabledControls;
  final bool debugEnabled;

  String nameFor(String fallback) {
    if (roomName.trim().isNotEmpty) return roomName.trim();
    if (displayName.trim().isNotEmpty) return displayName.trim();
    return fallback;
  }

  DeviceDisplayConfig copyWith({
    bool? showInHome,
    String? displayName,
    String? roomName,
    Set<HomeSensor>? enabledSensors,
    Set<HomeControl>? enabledControls,
    bool? debugEnabled,
  }) {
    return DeviceDisplayConfig(
      showInHome: showInHome ?? this.showInHome,
      displayName: displayName ?? this.displayName,
      roomName: roomName ?? this.roomName,
      enabledSensors: enabledSensors ?? this.enabledSensors,
      enabledControls: enabledControls ?? this.enabledControls,
      debugEnabled: debugEnabled ?? this.debugEnabled,
    );
  }

  Map<String, Object> toStorageJson() {
    return {
      'showInHome': showInHome,
      'displayName': displayName,
      'roomName': roomName,
      'enabledSensors': enabledSensors.map((sensor) => sensor.name).toList(),
      'enabledControls': enabledControls
          .map((control) => control.name)
          .toList(),
      'debugEnabled': debugEnabled,
    };
  }

  factory DeviceDisplayConfig.fromStorageJson(Map<String, dynamic> json) {
    return DeviceDisplayConfig(
      showInHome: json['showInHome'] != false,
      displayName: json['displayName']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
      enabledSensors: _readSensors(json['enabledSensors']),
      enabledControls: _readControls(json['enabledControls']),
      debugEnabled: json['debugEnabled'] == true,
    );
  }

  static Set<HomeSensor> _readSensors(Object? value) {
    if (value is! List) {
      return const {
        HomeSensor.temperature,
        HomeSensor.co2,
        HomeSensor.lux,
        HomeSensor.presence,
      };
    }
    return value
        .map(
          (item) => HomeSensor.values
              .where((sensor) => sensor.name == item)
              .firstOrNull,
        )
        .whereType<HomeSensor>()
        .toSet();
  }

  static Set<HomeControl> _readControls(Object? value) {
    if (value is! List) {
      return const {HomeControl.ac, HomeControl.projector, HomeControl.lights};
    }
    return value
        .map(
          (item) => HomeControl.values
              .where((control) => control.name == item)
              .firstOrNull,
        )
        .whereType<HomeControl>()
        .toSet();
  }
}

enum HomeSensor { temperature, co2, lux, presence }

enum HomeControl { ac, projector, lights }
