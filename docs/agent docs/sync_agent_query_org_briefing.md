# Task Briefing: Integration & Database Sync Agent (`sync_agent`)

**Task**: Print resolved InfluxDB organization on every query execution in `InfluxDbService`.

## Requirements
1. Modify `lib/services/influxdb_service.dart`.
2. In the `_query()` method, add `debugPrint('Using InfluxDB Organization: $org');` right after `final org = await _resolveOrg();`.
3. Check that only `influxdb_service.dart` is modified during this run.

## File Boundary
- Allowed file: `lib/services/influxdb_service.dart`
