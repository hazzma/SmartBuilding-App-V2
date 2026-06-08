# Task Briefing: Integration & Database Sync Agent (`sync_agent`)

**Task**: Integrate `ScheduleDatabaseService` into the schedule saving flow in `ScheduleScreen`.

## Requirements
1. Import `../services/schedule_database_service.dart`.
2. Construct a `ClassSchedule` object in `_saveDaySchedule` from the updated day and session code.
3. Call `const ScheduleDatabaseService().uploadSchedule(scheduleObj)`.
4. Check that only `schedule_screen.dart` is modified during this run.

## File Boundary
- Allowed file: `lib/screens/schedule_screen.dart`
