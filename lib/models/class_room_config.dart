// EDIT_TARGET: class_room_config.dart
// EDIT_PURPOSE: Defines classroom configuration.
// EDIT_REASON: FSD V2 makes className the single source of truth for room identity.

class ClassRoomConfig {
  static const Set<String> supportedSensors = {
    'temperature',
    'lux',
    'presence',
  };

  const ClassRoomConfig({
    required this.id,
    required this.className,
    required this.displayName,
    this.buildingName = 'Building A',
    this.floorName = 'Floor A',
    this.showInHome = true,
    this.enabledSensors = const <String>[],
    this.detectedSensors = const <String>[],
    this.enabledControls = const <String>[],
  });

  final String id;
  final String className;
  final String displayName;
  final String buildingName;
  final String floorName;
  final bool showInHome;
  final List<String> enabledSensors;
  final List<String> detectedSensors;
  final List<String> enabledControls;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'className': className,
      'displayName': displayName,
      'buildingName': buildingName,
      'floorName': floorName,
      'showInHome': showInHome,
      'enabledSensors': enabledSensors,
      'detectedSensors': detectedSensors,
      'enabledControls': enabledControls,
    };
  }

  factory ClassRoomConfig.fromJson(Map<String, dynamic> json) {
    final enabledSensors =
        (json['enabledSensors'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .where(supportedSensors.contains)
            .toList();

    return ClassRoomConfig(
      id: json['id'] as String? ?? '',
      className: json['className'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      buildingName: json['buildingName'] as String? ??
          _buildingNameFromClassName(json['className'] as String? ?? ''),
      floorName: json['floorName'] as String? ??
          _floorNameFromClassName(json['className'] as String? ?? ''),
      showInHome: json['showInHome'] as bool? ?? true,
      enabledSensors: enabledSensors,
      detectedSensors: (json['detectedSensors'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .where(supportedSensors.contains)
              .toList() ??
          enabledSensors,
      enabledControls: (json['enabledControls'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

String _buildingNameFromClassName(String className) {
  if (className.isEmpty) {
    return 'Building A';
  }
  return 'Building ${className[0].toUpperCase()}';
}

String _floorNameFromClassName(String className) {
  if (className.length < 2) {
    return 'Floor 1';
  }
  final floorNumber = int.tryParse(className[1]);
  return floorNumber == null ? 'Floor 1' : 'Floor $floorNumber';
}
