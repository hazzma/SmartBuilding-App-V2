# Changelog - Version 2.1.0

Release date: June 3, 2026

## Summary

Version 2.1.0 refines the classroom monitoring flow for the Smart Building Flutter app. This update focuses on clearer building/classroom organization, a stronger Home dashboard overview, and alignment between the FSD and the current app behavior.

## Added

- Added an English FSD version for clearer review and implementation guidance.
- Added Home dashboard summary blocks for:
  - Total registered classes.
  - Active classes.
  - Active alerts.
- Added an active alerts list to the bottom area of the Home screen.
- Added classroom grouping by floor and building in the Classes screen.
- Added dummy classroom data for buildings `L`, `K`, and `R`:
  - `L1D`: all sensors and controls.
  - `K1C`: light and projector controls only.
  - `R1A`: sensors only.
  - `L3A`: no sensors or controls.
  - `L3B`: all sensors and controls.
  - `L2A`: temperature sensor and AC control.
  - `K2C`: no sensors or controls.
- Added `buildingName`, `floorName`, and master-detected sensor metadata support to classroom configuration.

## Changed

- Renamed the Devices navigation concept to Classes for the classroom-focused workflow.
- Updated the Classes screen so classrooms expand on tap to show details instead of using a separate edit icon.
- Changed classroom sensor configuration from manual sensor selection to master-device detected sensor display.
- Updated classroom cards to show occupancy, alert, and active-status indicators.
- Updated default seed classroom data from the old `A101/B202` examples to the new `L/K/R` dummy classroom set.

## Removed

- Removed swipe-to-delete from the Home classroom drawer.
- Removed the redundant classroom edit icon from classroom cards.

## Notes

- All sensor readings and classroom status values are still placeholder/dummy data for now.
- Removing a classroom from the app only removes local display/configuration and does not delete a physical MQTT device.
- Existing custom saved classrooms are preserved. Only the old default seed classrooms are replaced by the new dummy data.

## Verification

- `flutter analyze` passed with no issues.
- `flutter test` passed.
