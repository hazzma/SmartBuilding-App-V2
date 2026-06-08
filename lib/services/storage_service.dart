// EDIT_TARGET: storage_service.dart
// EDIT_PURPOSE: Persists classroom and schedule configuration locally.
// EDIT_REASON: FSD V2 requires local storage for classroom and schedule setup.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/class_room_config.dart';
import '../models/class_schedule.dart';

class StorageService {
  static const String _classRoomsKey = 'class_room_configs';
  static const String _schedulesKey = 'class_schedules';

  Future<void> saveClassRoomConfigs(List<ClassRoomConfig> configs) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = configs.map((config) => config.toJson()).toList();
    await preferences.setString(_classRoomsKey, jsonEncode(encoded));
  }

  Future<List<ClassRoomConfig>> loadClassRoomConfigs() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_classRoomsKey);
    if (raw == null || raw.isEmpty) {
      return <ClassRoomConfig>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => ClassRoomConfig.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSchedules(List<ClassSchedule> schedules) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = schedules.map((schedule) => schedule.toJson()).toList();
    await preferences.setString(_schedulesKey, jsonEncode(encoded));
  }

  Future<List<ClassSchedule>> loadSchedules() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_schedulesKey);
    if (raw == null || raw.isEmpty) {
      return <ClassSchedule>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => ClassSchedule.fromJson(item as Map<String, dynamic>))
        .toList();
  }

}
