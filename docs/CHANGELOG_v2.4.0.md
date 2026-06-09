# Changelog - Version 2.4.0

Release date: June 9, 2026

## Summary

Version 2.4.0 introduces a major codebase minimization and simplification, eliminating unused packages, files, models, and custom widgets to keep the source structure clean, lightweight, and focused purely on core InfluxDB 2.x API sync and Firebase Authentication.

## Deleted

- **Unused Widgets**: Deleted obsolete custom widgets `power_button.dart`, `step_button.dart`, and `sensor_graph.dart`.
- **Unused Services**: Deleted `automation_service.dart`, `storage_service.dart`, and `schedule_database_service.dart` since all synchronization is handled directly by InfluxDB.
- **Unused Models**: Deleted `class_schedule.dart`, `automation_state.dart`, `class_automation_config.dart`, `control_state.dart`, `sensor_data.dart`, and `auth_state.dart`.
- **Unused Tests**: Deleted `test/class_schedule_test.dart`.

## Changed

- **Localized Schedule Sessions**: Defined the predefined `ScheduleSession` slots inside [schedule_screen.dart](file:///d:/Flutter_Projects/smartclass_v2/lib/screens/schedule_screen.dart) to fix the compilation error caused by the removal of the old `class_schedule.dart` model.
- **Inlined Authentication Properties**: Refactored [auth_service.dart](file:///d:/Flutter_Projects/smartclass_v2/lib/services/auth_service.dart) to inline authentication fields (`_currentUser`, `isAuthenticated`, `currentUserId`, `currentUserEmail`), completely removing references to the deleted `AuthState` model.
- **Simplified Classroom Configuration**: Refactored `ClassRoomConfig` and updated [app.dart](file:///d:/Flutter_Projects/smartclass_v2/lib/app.dart) to only populate essential metadata fields (`id`, `className`, `displayName`, `buildingName`, `floorName`), removing redundant configuration parameters.
- **Cleaned Up Dependencies**: Removed unused packages `fl_chart`, `shared_preferences`, and `calendar_date_picker2` from [pubspec.yaml](file:///d:/Flutter_Projects/smartclass_v2/pubspec.yaml) and cleaned up [widget_test.dart](file:///d:/Flutter_Projects/smartclass_v2/test/widget_test.dart) and [README.md](file:///d:/Flutter_Projects/smartclass_v2/README.md).
- **FSD and Documentation Alignment**: Updated [smart_building_app_fsd_v_2_FIXED_schedule.md](file:///d:/Flutter_Projects/smartclass_v2/docs/smart_building_app_fsd_v_2_FIXED_schedule.md) recommended structure and registry specs to exactly match our simplified codebase.

## Verification

- Verified that all compilation errors are successfully resolved and the codebase has zero dangling imports.
