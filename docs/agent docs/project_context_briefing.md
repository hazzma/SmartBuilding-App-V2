# Project Context Briefing

Welcome to the **SmartClass v2** Flutter project. This document serves as your onboarding context.

## 1. Project Goal
SmartClass is a Flutter application designed to monitor classroom parameters (temperature, lux, human presence) and control actuators (lamps, projectors, AC units) through a database-backed, automation-ready system using InfluxDB and MQTT.

## 2. Technical Stack
- **Framework**: Flutter (Dart)
- **Database**: InfluxDB 2.x (via http query/write APIs)
- **Actuators/Commands**: Controlled via InfluxDB writes (`classroom` and `classroom_schedule` measurements) that sync with MQTT brokers.

## 3. Directory Layout
- [lib/models/](file:///d:/Flutter_Projects/smartclass_v2/lib/models) - Contains state models (`influx_room_data.dart`, `class_schedule.dart`, `class_room_config.dart`).
- [lib/screens/](file:///d:/Flutter_Projects/smartclass_v2/lib/screens) - Screens for Home, Schedule, Classes, and Settings.
- [lib/services/](file:///d:/Flutter_Projects/smartclass_v2/lib/services) - Services for InfluxDB connectivity, authentication, automation rules, and local storage.
- [lib/widgets/](file:///d:/Flutter_Projects/smartclass_v2/lib/widgets) - Reusable components (`app_card.dart`, `app_badge.dart`, etc.).

## 4. Database Schema and Rules
- **Schedule Bitmask**: The class schedule is read and normalized as a 6-digit binary string representing scheduled sessions (e.g. `Monday = 010000`). It is written to InfluxDB as an integer (e.g., `10000` because leading zeros are not stored in integer values).
- **AC Int Code**: The AC control code represents state parameters (`power/temp/fan/swing`). It is stored as a quoted string (e.g. `"01/24/00/99"`) in InfluxDB to preserve formatting and leading zeros.
- **Rule 1 (Edit Purpose)**: Every modified code block must contain:
  ```dart
  // EDIT_TARGET: <file_or_section>
  // EDIT_PURPOSE: <what_changed>
  // EDIT_REASON: <why_changed>
  ```
- **Rule 2 (Simplicity)**: Avoid unnecessary architecture layers, keep widgets simple, and focus on deadlines.
