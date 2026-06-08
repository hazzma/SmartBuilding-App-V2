# Task Briefing: Integration & Database Sync Agent (`sync_agent`)

**Task**: Add temporary raw CSV query response logs to InfluxDbService.

## Requirements
1. Modify `lib/services/influxdb_service.dart`.
2. In the `_query()` method, add a print or debug print of the raw `body` returned from InfluxDB query endpoint.
3. Check that only `influxdb_service.dart` is modified during this run.

## File Boundary
- Allowed file: `lib/services/influxdb_service.dart`
