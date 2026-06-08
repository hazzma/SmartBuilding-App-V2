# Task Briefing: Integration & Database Sync Agent (`sync_agent`)

**Task**: Restore the room filter in `_loadLatestFieldsByRoom` in `InfluxDbService`.

## Requirements
1. Modify `lib/services/influxdb_service.dart`.
2. Restore the `roomFilter` line to:
   `final roomFilter = room == null ? '' : '  |> filter(fn: (r) => r.room == "${_escapeFlux(room)}")\n';`
3. Check that only `influxdb_service.dart` is modified during this run.

## File Boundary
- Allowed file: `lib/services/influxdb_service.dart`
