// EDIT_TARGET: test/class_schedule_test.dart
// EDIT_PURPOSE: Verifies fixed-session serialization and legacy schedule loading
// EDIT_REASON: Database uploads depend on stable session1-session6 integer flags

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_building_app/models/class_schedule.dart';

void main() {
  test('serializes selected sessions as six integer flags', () {
    const schedule = ClassSchedule(
      id: 'schedule-1',
      classRoomId: 'room-l1d',
      title: 'Example',
      sessionNumbers: [3, 4],
    );

    expect(schedule.sessionFlags, {
      'session1': 0,
      'session2': 0,
      'session3': 1,
      'session4': 1,
      'session5': 0,
      'session6': 0,
    });
    expect(schedule.startTime, '11:20');
    expect(schedule.endTime, '15:00');
  });

  test('loads old time-based schedules into matching sessions', () {
    final schedule = ClassSchedule.fromJson({
      'id': 'legacy',
      'classRoomId': 'room-l1d',
      'title': 'Legacy',
      'startTime': '09:20',
      'endTime': '11:00',
    });

    expect(schedule.sessionNumbers, [2]);
  });
}
