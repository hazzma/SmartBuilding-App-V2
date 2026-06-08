# Changelog - Version 2.3.0

Release date: June 8, 2026

## Summary

Version 2.3.0 introduces database synchronization stabilization, field and label adjustments, query performance fixes, and UI details screen refinements for SmartClass.

## Added

- **Presence Field Fallback Support**: Added fallbacks for alternative database fields `presence` and `motion` (e.g. on classrooms like `L1D` and `class102`) to ensure human presence is mapped accurately even with firmware field name variations.
- **Placeholder `-1` Sensor Handling**: Added filters to treat `-1` values in parsed fields (`temp`, `lux`, `human`) as `null` placeholders. Stale or inactive sensor measurements now display cleanly as `"-"` instead of invalid/raw values.
- **Yes/No Presence Formatting**: Created `_yesNoLabel` mapping to output boolean presence values as explicit user-facing `'yes'` or `'no'` text labels instead of `'on'` / `'off'`.

## Changed

- **Suhu to Temp Migration**: Renamed all query references and parsing lookups from `"suhu"` to `"temp"` to match the database's actual field keys.
- **Expanded Details Renaming**: Renamed metrics inside the classroom details card: `"Suhu"` is now `"temp"`, and `"Human"` is now `"presense"`.
- **OR-Based Query Field Optimization**: Replaced the buggy Flux `contains(...)` query filter in `_loadLatestFieldsByRoom` with an optimized, standard OR-based condition (`r._field == "temp" or r._field == "lux" ...`), solving the issue where all other fields besides temperature were being filtered out.
- **Slasheless AC Formatting**: Updated AC command payload construction to send contiguous 8-character codes (e.g. `"01180099"`) without slashes (`/`), matching firmware parser requirements.
- **Case-Insensitive Day Matching**: Updated `loadClassroomSchedule` to match day fields case-insensitively, preventing lowercase values like `"friday"` from failing to sync into the uppercase UI schedule table.
- **FSD Alignment with Codebase**: Fully updated the Functional Specification Document (FSD) to reflect actual app behavior:
  - Documented direct **InfluxDB 2.x Write/Query API** integration (replacing obsolete MQTT topic specs).
  - Documented AC control layout utilizing a **Slider**, **Switch**, and **Dropdown** inside the AC modal dialog.
  - Documented the correct **Home screen overview structure** (Total/Active/Alert blocks, campus light buttons, ongoing classes, active alerts lists) and the **Classes tab** expanded detail navigation.
  - Removed outdated MQTT settings instructions from the Settings tab.

## Verification

- Verified the deletion of classroom measurement data in InfluxDB 2 via endpoint POST requests.
- Verified that all classroom fields query successfully under the OR-based Flux query.
