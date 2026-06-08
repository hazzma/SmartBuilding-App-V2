// EDIT_TARGET: automation_service.dart
// EDIT_PURPOSE: Evaluates schedules and sends safe automation commands for rooms.
// EDIT_REASON: FSD V2 requires presence-aware automation with pre-start, recheck, conflict, and anti-spam guards.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/automation_state.dart';
import '../models/class_automation_config.dart';
import '../models/class_room_config.dart';
import '../models/class_schedule.dart';
import '../models/control_state.dart';
import '../models/sensor_data.dart';

class AutomationService extends ChangeNotifier {
  AutomationService({
    ClassAutomationConfig config = const ClassAutomationConfig(),
  }) : _config = config;

  ClassAutomationConfig _config;
  Timer? _timer;

  List<ClassRoomConfig> _rooms = <ClassRoomConfig>[];
  List<ClassSchedule> _schedules = <ClassSchedule>[];
  final Map<String, SensorData> _sensorByRoomId = <String, SensorData>{};
  final Map<String, ControlState> _controlByRoomId = <String, ControlState>{};
  final Map<String, AutomationRoomStatus> _statusByRoomId =
      <String, AutomationRoomStatus>{};
  final Map<String, DateTime> _lastRecheckByRoomId = <String, DateTime>{};
  final Set<String> _preStartedScheduleIds = <String>{};
  final Set<String> _shutdownScheduleIds = <String>{};
  final Set<String> _manualOverrideRoomIds = <String>{};

  Map<String, AutomationRoomStatus> get currentStatus =>
      Map.unmodifiable(_statusByRoomId);

  AutomationRoomStatus statusFor(String classRoomId) {
    return _statusByRoomId[classRoomId] ?? AutomationRoomStatus.idle;
  }

  void updateConfig(ClassAutomationConfig config) {
    _config = config;
    notifyListeners();
  }

  void updateInputs({
    required List<ClassRoomConfig> rooms,
    required List<ClassSchedule> schedules,
    required Map<String, SensorData> sensorByRoomId,
    required Map<String, ControlState> controlByRoomId,
  }) {
    _rooms = List<ClassRoomConfig>.from(rooms);
    _schedules = List<ClassSchedule>.from(schedules);
    _sensorByRoomId
      ..clear()
      ..addAll(sensorByRoomId);
    _controlByRoomId
      ..clear()
      ..addAll(controlByRoomId);
  }

  void start() {
    _timer?.cancel();
    evaluate();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => evaluate());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void markManualOverride(String classRoomId) {
    _manualOverrideRoomIds.add(classRoomId);
  }

  void clearManualOverride(String classRoomId) {
    _manualOverrideRoomIds.remove(classRoomId);
  }

  void evaluate({DateTime? now}) {
    if (!_config.scheduleAutomationEnabled) {
      return;
    }

    final currentTime = now ?? DateTime.now();
    final roomsById = <String, ClassRoomConfig>{
      for (final room in _rooms) room.id: room,
    };

    for (final schedule in _schedules.where((item) => item.automationEnabled)) {
      final room = roomsById[schedule.classRoomId];
      if (room == null || !_occursOn(schedule, currentTime)) {
        continue;
      }

      final selectedSessions = schedule.sessionNumbers
          .map(ScheduleSession.byNumber)
          .toList()
        ..sort((a, b) => a.number.compareTo(b.number));

      final activeSession = selectedSessions.cast<ScheduleSession?>().firstWhere(
            (session) {
              final start = _timeOnDate(currentTime, session!.start);
              final end = _timeOnDate(currentTime, session.end);
              return !currentTime.isBefore(start) && currentTime.isBefore(end);
            },
            orElse: () => null,
          );
      if (activeSession != null) {
        _setStatus(room.id, AutomationRoomStatus.scheduledActive);
        continue;
      }

      var preStartTriggered = false;
      for (final session in selectedSessions) {
        final sessionNumber = session.number;
        final start = _timeOnDate(currentTime, session.start);
        final preStartAt = start.subtract(
          Duration(minutes: _config.preStartMinutes),
        );
        final occurrenceKey = _occurrenceKey(
          schedule,
          currentTime,
          sessionNumber,
        );

        if (_isWithinMinute(currentTime, preStartAt) &&
            !_preStartedScheduleIds.contains(occurrenceKey)) {
          _handlePreStart(room, occurrenceKey);
          preStartTriggered = true;
        }
      }
      if (preStartTriggered) {
        continue;
      }

      final endedSessions = selectedSessions.where((session) {
        final end = _timeOnDate(currentTime, session.end);
        return !currentTime.isBefore(end);
      }).toList();
      if (endedSessions.isEmpty) {
        continue;
      }

      final lastEndedSession = endedSessions.last;
      final occurrenceKey = _occurrenceKey(
        schedule,
        currentTime,
        lastEndedSession.number,
      );
      if (!_shutdownScheduleIds.contains(occurrenceKey)) {
        _handlePostClass(room, currentTime, occurrenceKey);
      }
    }
  }

  void _handlePreStart(ClassRoomConfig room, String occurrenceKey) {
    _preStartedScheduleIds.add(occurrenceKey);
    _setStatus(room.id, AutomationRoomStatus.preStarting);

    if (_manualOverrideRoomIds.contains(room.id)) {
      return;
    }

    final currentState = _controlByRoomId[room.id] ?? const ControlState();
    if (_config.autoTurnOnLights) {
      _publishLampTarget(room, currentState, true);
    }
    if (_config.autoTurnOnAc) {
      _publishAcTarget(
        room,
        currentState,
        power: true,
        targetTemp: _config.defaultAcTargetTemperature,
      );
    }
    if (_config.autoTurnOnProjector) {
      _publishProjectorTarget(room, currentState, true);
    }
  }

  void _handlePostClass(
    ClassRoomConfig room,
    DateTime now,
    String occurrenceKey,
  ) {
    final sensor = _sensorByRoomId[room.id];
    if (sensor == null || sensor.isStale || sensor.humanPresence == null) {
      _setStatus(room.id, AutomationRoomStatus.pausedPresenceUnavailable);
      return;
    }

    if (sensor.humanPresence == true) {
      _setStatus(room.id, AutomationRoomStatus.waitingEmpty);
      final lastRecheck = _lastRecheckByRoomId[room.id];
      final recheckDuration = Duration(
        minutes: _config.emptyRoomRecheckMinutes,
      );
      if (lastRecheck == null ||
          now.difference(lastRecheck) >= recheckDuration) {
        _lastRecheckByRoomId[room.id] = now;
      }
      return;
    }

    if (_hasSoonNextClass(room.id, now)) {
      _setStatus(room.id, AutomationRoomStatus.scheduledActive);
      return;
    }

    _setStatus(room.id, AutomationRoomStatus.shuttingDown);
    final currentState = _controlByRoomId[room.id] ?? const ControlState();
    _publishLampTarget(room, currentState, false);
    _publishAcTarget(room, currentState, power: false);
    _publishProjectorTarget(room, currentState, false);
    _shutdownScheduleIds.add(occurrenceKey);
    _manualOverrideRoomIds.remove(room.id);
    _setStatus(room.id, AutomationRoomStatus.idle);
  }

  void _publishLampTarget(
    ClassRoomConfig room,
    ControlState currentState,
    bool power,
  ) {
    final hasDifferentState = currentState.lampChannels.isEmpty ||
        currentState.lampChannels.any((channel) => channel.power != power);
    if (!hasDifferentState) {
      return;
    }

    _publishCommand(
      room.className,
      <String, dynamic>{'power': power},
    );
  }

  void _publishAcTarget(
    ClassRoomConfig room,
    ControlState currentState, {
    required bool power,
    int? targetTemp,
  }) {
    final samePower = currentState.acPower == power;
    final sameTemp =
        targetTemp == null || currentState.acTargetTemp == targetTemp;
    if (samePower && sameTemp) {
      return;
    }

    _publishCommand(
      room.className,
      <String, dynamic>{
        'power': power,
        if (targetTemp != null) 'targetTemp': targetTemp,
      },
    );
  }

  void _publishProjectorTarget(
    ClassRoomConfig room,
    ControlState currentState,
    bool power,
  ) {
    if (currentState.projectorPower == power) {
      return;
    }

    _publishCommand(
      room.className,
      <String, dynamic>{'power': power},
    );
  }

  void _publishCommand(String className, Map<String, dynamic> payload) {
    debugPrint('Dummy automation command for $className: $payload');
  }

  bool _hasSoonNextClass(String classRoomId, DateTime now) {
    final recheckWindow = Duration(minutes: _config.emptyRoomRecheckMinutes);
    return _schedules.any((schedule) {
      if (schedule.classRoomId != classRoomId || !schedule.automationEnabled) {
        return false;
      }
      if (!_occursOn(schedule, now)) {
        return false;
      }
      return schedule.sessionNumbers.any((sessionNumber) {
        final session = ScheduleSession.byNumber(sessionNumber);
        final start = _timeOnDate(now, session.start);
        return start.isAfter(now) && start.difference(now) < recheckWindow;
      });
    });
  }

  bool _occursOn(ClassSchedule schedule, DateTime date) {
    if (schedule.date != null) {
      final scheduledDate = schedule.date!;
      return scheduledDate.year == date.year &&
          scheduledDate.month == date.month &&
          scheduledDate.day == date.day;
    }
    return schedule.daysOfWeek.contains(date.weekday);
  }

  DateTime _timeOnDate(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _isWithinMinute(DateTime currentTime, DateTime targetTime) {
    return currentTime.difference(targetTime).abs() <
        const Duration(minutes: 1);
  }

  String _occurrenceKey(
    ClassSchedule schedule,
    DateTime date,
    int sessionNumber,
  ) {
    return '${schedule.id}:${date.year}-${date.month}-${date.day}:session$sessionNumber';
  }

  void _setStatus(String classRoomId, AutomationRoomStatus status) {
    if (_statusByRoomId[classRoomId] == status) {
      return;
    }
    _statusByRoomId[classRoomId] = status;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
