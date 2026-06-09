// EDIT_TARGET: class_room_config.dart
// EDIT_PURPOSE: Defines classroom configuration.
// EDIT_REASON: FSD V2 makes className the single source of truth for room identity.

class ClassRoomConfig {
  const ClassRoomConfig({
    required this.id,
    required this.className,
    required this.displayName,
    required this.buildingName,
    required this.floorName,
  });

  final String id;
  final String className;
  final String displayName;
  final String buildingName;
  final String floorName;
}
