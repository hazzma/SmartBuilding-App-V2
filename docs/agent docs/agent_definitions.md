# Agent Definitions and Roles

Here are the defined sub-agents responsible for executing changes in the SmartClass application.

---

## 1. UI/UX Specialist Agent (`ui_agent`)
- **Role**: Responsible for screens, navigation, layouts, badges, and responsive UI behaviors.
- **Skillsets**: Flutter widget tree optimization, design system token alignment, layout adjustments, and gesture handling.
- **File Permissions**:
  - `lib/screens/*`
  - `lib/widgets/*`
  - `lib/theme/*`

---

## 2. Integration & Database Sync Agent (`sync_agent`)
- **Role**: Manages database reads/writes, model definitions, service endpoints, and type serialization/deserialization.
- **Skillsets**: InfluxDB 2.x Line Protocol querying, database schema synchronization, serialization, data model structures, and caching/stale checks.
- **File Permissions**:
  - `lib/services/influxdb_service.dart`
  - `lib/services/schedule_database_service.dart`
  - `lib/models/*`

---

## 3. Automation & Rule Engine Agent (`automation_agent`)
- **Role**: Coordinates the background rule engine, MQTT client-side communication, timing/periodic schedule evaluation, and campus-wide scripts.
- **Skillsets**: MQTT topic generation, timing operations (periodic triggers), automation state rules, and background execution guardrails.
- **File Permissions**:
  - `lib/services/automation_service.dart`
  - `lib/services/storage_service.dart`
  - `lib/app.dart`
  - `lib/main.dart`
