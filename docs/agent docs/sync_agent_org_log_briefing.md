# Task Briefing: Integration & Database Sync Agent (`sync_agent`)

**Task**: Add resolved InfluxDB organization logs in `InfluxDbService`.

## Requirements
1. Modify `lib/services/influxdb_service.dart`.
2. In the `_resolveOrg()` method, add `debugPrint('Resolved InfluxDB Organization: $_org');` after resolving the organization.
3. Check that only `influxdb_service.dart` is modified during this run.

## File Boundary
- Allowed file: `lib/services/influxdb_service.dart`
