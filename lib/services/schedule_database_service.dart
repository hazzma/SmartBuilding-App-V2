// EDIT_TARGET: lib/services/schedule_database_service.dart
// EDIT_PURPOSE: Defines the database upload boundary for schedule session flags
// EDIT_REASON: Schedule persistence will later send six fixed session booleans

import 'package:flutter/foundation.dart';

import '../models/class_schedule.dart';

class ScheduleDatabaseService {
  const ScheduleDatabaseService();

  Future<void> uploadSchedule(ClassSchedule schedule) async {
    final payload = <String, dynamic>{
      'scheduleId': schedule.id,
      'classRoomId': schedule.classRoomId,
      'date': schedule.date?.toIso8601String(),
      'daysOfWeek': schedule.daysOfWeek,
      ...schedule.sessionFlags,
    };

    debugPrint('Dummy schedule database upload: $payload');
  }
}
