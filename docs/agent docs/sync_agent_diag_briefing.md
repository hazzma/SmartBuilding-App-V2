# Task Briefing: Integration & Database Sync Agent (`sync_agent`)

**Task**: Temporarily disable the specific room filter in `_loadLatestFieldsByRoom` to log all fields.

## Requirements
1. Modify `lib/services/influxdb_service.dart`.
2. In `_loadLatestFieldsByRoom()`, temporarily comment out the `roomFilter` line or replace it with an empty string so that the database queries all rooms.
3. Check that only `influxdb_service.dart` is modified during this run.

## File Boundary
- Allowed file: `lib/services/influxdb_service.dart`
