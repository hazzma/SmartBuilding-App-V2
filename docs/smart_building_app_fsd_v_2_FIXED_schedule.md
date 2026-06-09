# Smart Building App FSD V2

## 0. Core Rules

### Rule 1 - Every Code Block Must Explain Its Edit Purpose

Every new or changed code block should include a short command-style comment explaining what part of the app it edits, what changed, and why the change is needed.

Required format:

```dart
// EDIT_TARGET: <file_or_section_name>
// EDIT_PURPOSE: <what_is_changed>
// EDIT_REASON: <why_this_change_is_needed>
```

Example:

```dart
// EDIT_TARGET: app_button.dart
// EDIT_PURPOSE: Create the reusable primary button for the app
// EDIT_REASON: Shared button styling keeps the UI consistent and easy to adjust
class AppButton extends StatelessWidget {
  const AppButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {},
      child: const Text('Save'),
    );
  }
}
```

The purpose of this rule is to keep debugging, review, and manual edits clear as the codebase grows.

### Rule 2 - Keep Flutter Code Simple

This project is deadline-sensitive. The code must be quick to open, read, debug, modify, and learn from.

Implementation rules:

```txt
Prefer simple StatelessWidget / StatefulWidget implementations.
Avoid unnecessary architecture layers.
Avoid overusing inheritance.
Avoid overusing generic widget builders.
Avoid hidden global state.
Avoid deeply nested widget trees.
Avoid clever code.
Use clear file names.
Use clear class names.
Keep each widget file focused.
```

Recommended file structure:

```txt
lib/
  main.dart
  app.dart
  theme/
  models/
    class_room_config.dart
    influx_room_data.dart
  services/
    auth_service.dart
    influxdb_service.dart
  screens/
    auth_screen.dart
    home_screen.dart
    schedule_screen.dart
    devices_screen.dart (Classes Screen)
    settings_screen.dart
  widgets/
    app_badge.dart
    app_button.dart
    app_card.dart
```

If a feature can be implemented in one readable widget file, do not split it into five files. If local state is enough, do not create complex global state. If an abstraction makes deadline debugging harder, do not add it.

Every non-obvious function must include a short comment explaining why it exists. Do not comment obvious Flutter boilerplate.

## 1. App Requirement Alignment

The Flutter app controls and monitors classroom parameters and actuator states by communicating directly with **InfluxDB 2.x** using HTTP Write/Query APIs.

The app shall:

- Read and query classroom status fields from the database.
- Write control commands and actuator target states directly to InfluxDB.
- Display the list of configured classrooms.
- Group classrooms by floor in the Classes screen.
- Allow expanding/collapsing classroom cards to see details and update controls.
- Query and sync schedules from the database, displaying them case-insensitively.

Core data flow:

```txt
Flutter App
  -> HTTP Query API
InfluxDB (Read classroom/schedule)
  -> HTTP Write API
InfluxDB (Write control states/schedule)
```

### 1.1 Database Communication and Schema Requirement

The app communicates directly with InfluxDB v2.x using the following organization and bucket configuration:
- **Bucket**: `SmartClass`
- **Measurement**: `classroom` (for metrics and actuators), `classroom_schedule` (for classroom schedules)
- **Tag**: `room` (value is the classroom name, e.g., `"HD01"`, `"L1D"`)

Fields within the `classroom` measurement:
- `temp` (or fallbacks: `suhu`, `temperature`): classroom temperature
- `lux` (or fallback: `light`): ambient light intensity
- `human` (or fallbacks: `presence`, `motion`): human presence detection
- `led` (or fallback: `LED`): LED lamp state (`1` / `0`)
- `projector`: projector state (`1` / `0`)
- `ac`: AC command state string
- `alert`: alert flag
- `active`: schedule active flag

### 1.2 Classroom Registry Requirement

The app stores the list of classrooms shown in the UI.

Each classroom config minimally contains:

- `id`
- `className`
- `displayName`
- `buildingName`
- `floorName`

Classroom config items can be:

- Grouped by floor on the Classes screen.
- Expanded to show details and controls.

### 1.3 State Payload Parsing Requirement

The app queries latest data using an optimized Flux query with OR-based field checking:
```flux
from(bucket: "SmartClass")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "classroom")
  |> filter(fn: (r) => r._field == "temp" or r._field == "lux" or r._field == "human" or ...)
```
Parsing rules:
- Stale or unavailable placeholder values of `-1` are mapped to `null` and displayed as `"-"` in the UI.
- Presence values are formatted to output `'yes'` or `'no'` text labels.
- AC states are parsed from a contiguous 8-digit string or slash-separated values.

### 1.4 Command Payload Requirement

The app writes actuator commands directly to InfluxDB:
- **LED/Projector**: Written as integers (`1` for ON, `0` for OFF).
- **AC Code**: Constructed as a contiguous 8-digit string `ppttffss` (without slashes) where:
  - `pp`: Power (`01` = ON, `00` = OFF)
  - `tt`: Temperature in °C (padded, e.g., `18`, `24`)
  - `ff`: Fan Speed (padded, e.g., `00` for Auto, `01` for Low)
  - `ss`: Swing setting (default `99`)
  Example line protocol: `classroom,room=HD01 ac="01180099"`

### 1.5 Navigation and App Shell

Simplified navigation:

```txt
Auth -> AuthScreen before AppShell
Home Overview -> Home screen
Classroom Monitoring & Controls -> Classes tab (DevicesScreen)
Settings -> Settings tab (Sign Out only)
```

### 1.6 Home Screen Requirement

The Home screen is a building overview dashboard.

Top area:
- A row with 3 blocks:
  - Total Classes: count of registered classrooms.
  - Active Classes: count of classrooms where `active` is true.
  - Alerts: count of classrooms where `alert` is active.

Middle area:
- Global/campus-wide All Lights On and All Lights Off buttons.

Bottom area:
- Active Alerts list: displays warnings for classrooms with active alerts.
- Ongoing Classes list: queries the latest `classroom_schedule` fields from InfluxDB, matches the current weekday and predefined session, and refreshes once per minute.

### 1.7 Classes Screen Requirement (DevicesScreen)

The Classes screen groups classrooms by floor and supports card expansion.

Collapsed classroom card indicators:
- **Person icon**: green if occupied (`human == true`), grey otherwise.
- **Alert icon**: orange if an alert exists, grey otherwise.
- **Status circle**: blue if active, grey otherwise.

Expanded classroom details:
- Editable classroom metadata (`className`, `displayName`, `floorName`).
- Metric badges displaying `temp`, `Lux`, and `presense` (with values `yes`/`no` or `"-"` for placeholders/no data).
- Interactive power buttons for LED and Projector.
- Interactive AC badge that opens the AC Control Dialog.
- Each sensor/control badge contains an alert icon. The icon is orange when that specific field has an active alert and grey otherwise.
- The expanded details area does not use a separate classroom-level Alert badge.

## 2. Flutter Widget Usage Summary

The app uses Flutter built-in widgets as the base of reusable components:
- `FilledButton`, `ElevatedButton`, `TextButton`, `IconButton`
- `TextField`, `DropdownButtonFormField`, `Switch`, `Slider`
- `CircularProgressIndicator`
- `Card`, `Container`, `Divider`
- `Dialog`, `AlertDialog`
- `SnackBar`

## 3. Reusable Widget Mapping

| App Widget | Flutter Widget | Purpose |
|---|---|---|
| `AppButton` | `FilledButton` / `ElevatedButton` | Primary actions |
| `AppDropdown` | `DropdownButtonFormField` | Option selection |
| `AppCard` | `Card` / `Container` | Content wrapper |
| `AppBadge` | `Container` + `Text` | Status labels |
| `AppLoading` | `CircularProgressIndicator` | Blocking loading |

## 4. Control Input Rules

Actuator controls inside the classroom details card utilize:
- **LED/Projector**: Tap toggles power.
- **AC Control**: Handled in a modal dialog (`_AcControlDialog`):
  - SwitchListTile for AC Power.
  - Slider for Temperature adjustments (16°C - 30°C).
  - DropdownButtonFormField for Fan Speed selection.

## 5. Color Palette

Main colors:
- `primary`: `#2563EB` (Primary actions)
- `background`: `#F8FAFC` (Main background)
- `surface`: `#FFFFFF` (Cards, modals)
- `surfaceSoft`: `#F1F5F9` (Soft details)

Status colors:
- `success`: `#22C55E` (Connected / ON)
- `warning`: `#F59E0B` (Attention)
- `error`: `#EF4444` (Critical / OFF)
- `offline`: `#94A3B8` (Stale / Inactive)

## 6. Font Template

Default font: `Inter`
Fallback: `Roboto`

## 7. App Structure Draft

```txt
AuthGate
  If not logged in: AuthScreen
  If logged in: AppShell
    Home (Building Overview Stats, Campus Lights Buttons, Active Alerts, Ongoing Classes)
    Schedule (Classroom schedule table)
    Classes (Grouped rooms list, expandable controls, metrics)
    Settings (Sign Out)
```

## 8. Schedule And Automation Requirement

Schedule is a main tab for manually configuring classroom usage times.

Schedules are written directly to the `classroom_schedule` measurement in InfluxDB:
- References `room` tag (value is classroom `className`).
- Day fields (`Monday`, `Tuesday`, ..., `sunday`) store the bitmask schedule code as an integer.
- The app matches schedule day fields case-insensitively to ensure compatibility with various database entries.

Predefined sessions:
- Session 1: 07:20-09:00
- Session 2: 09:20-11:00
- Session 3: 11:20-13:00
- Session 4: 13:20-15:00
- Session 5: 15:20-17:00
- Session 6: 17:20-19:00

## 9. Firebase Authentication Requirement

Firebase Authentication is used only as the user identity system:
- Decide who may access the app.
- Supports Email + Password signing in/out.
- User accounts are created manually in Firebase Authentication. The app does not support registration.

## 10. Final Implementation Guardrails

1. Keep authentication sign-in only; accounts are provisioned manually.
2. Communicate with InfluxDB 2.x directly; MQTT communication is not used.
3. Keep Settings screen limited to account functions (Sign Out).
4. Use Slider and Dropdown inside the AC dialog panel to select target temperature and fan speed.
5. Format AC control states as contiguous 8-digit strings without slashes.
6. Handle InfluxDB placeholder values of `-1` by mapping them to null (`"-"` in UI).
7. Map day fields case-insensitively to prevent casing sync mismatches.
