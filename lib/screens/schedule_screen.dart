// EDIT_TARGET: lib/screens/schedule_screen.dart
// EDIT_PURPOSE: Classroom weekly repeating schedule manager
// EDIT_REASON: Replaces calendar-based dates with weekly repeating sessions based on the DB schema

import 'package:flutter/material.dart';

import '../models/class_room_config.dart';
import '../models/class_schedule.dart';
import '../services/influxdb_service.dart';
import '../services/schedule_database_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
    required this.rooms,
    required this.influxDbService,
    required this.refreshSignal,
  });

  final List<ClassRoomConfig> rooms;
  final InfluxDbService influxDbService;
  final int refreshSignal;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  ClassRoomConfig? _selectedRoom;
  Map<String, String> _scheduleData = {};
  bool _isLoading = false;
  String? _error;

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.rooms.isNotEmpty) {
      _selectedRoom = widget.rooms.first;
      _loadSchedule();
    }
  }

  @override
  void didUpdateWidget(covariant ScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal != oldWidget.refreshSignal) {
      _loadSchedule();
    }
    if (widget.rooms.isNotEmpty) {
      if (_selectedRoom == null || !widget.rooms.any((r) => r.id == _selectedRoom!.id)) {
        setState(() {
          _selectedRoom = widget.rooms.first;
        });
        _loadSchedule();
      } else {
        final updatedRoom = widget.rooms.firstWhere((r) => r.id == _selectedRoom!.id);
        if (updatedRoom != _selectedRoom) {
          setState(() {
            _selectedRoom = updatedRoom;
          });
        }
      }
    }
  }

  Future<void> _loadSchedule() async {
    if (_selectedRoom == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final schedule = await widget.influxDbService.loadClassroomSchedule(_selectedRoom!.className);
      if (mounted) {
        setState(() {
          _scheduleData = schedule;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveDaySchedule(String day, String code) async {
    if (_selectedRoom == null) return;
    final oldCode = _scheduleData[day] ?? '000000';
    if (oldCode == code) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.influxDbService.writeClassroomSchedule(
        _selectedRoom!.className,
        day,
        code,
      );

      final sessionNumbers = <int>[];
      for (var i = 0; i < code.length; i++) {
        if (code[i] == '1') {
          sessionNumbers.add(i + 1);
        }
      }

      final weekdayIndex = _weekdays.indexOf(day) + 1;
      final scheduleObj = ClassSchedule(
        id: 'sched-${_selectedRoom!.id}-${day.toLowerCase()}',
        classRoomId: _selectedRoom!.id,
        title: '$day Schedule',
        daysOfWeek: [weekdayIndex],
        sessionNumbers: sessionNumbers,
        automationEnabled: true,
      );

      await const ScheduleDatabaseService().uploadSchedule(scheduleObj);

      if (mounted) {
        setState(() {
          _scheduleData[day] = code;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully updated $day schedule.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save schedule: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppCard(
                child: AppDropdown<String>(
                  label: 'Select Classroom',
                  value: _selectedRoom?.id,
                  items: widget.rooms
                      .map(
                        (room) => DropdownMenuItem<String>(
                          value: room.id,
                          child: Text(room.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (roomId) {
                    if (roomId != null) {
                      final room = widget.rooms.firstWhere((r) => r.id == roomId);
                      setState(() {
                        _selectedRoom = room;
                      });
                      _loadSchedule();
                    }
                  },
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: CircularProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_error!, style: AppTextStyles.caption),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _selectedRoom == null
                  ? const Center(child: Text('No classroom selected.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _weekdays.length,
                      itemBuilder: (context, index) {
                        final day = _weekdays[index];
                        final code = _scheduleData[day] ?? '000000';
                        final activeSessions = _activeSessionsForCode(code);

                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(day, style: AppTextStyles.sectionTitle),
                                    const SizedBox(height: 8),
                                    if (activeSessions.isEmpty)
                                      const Text(
                                        'No sessions scheduled',
                                        style: AppTextStyles.caption,
                                      )
                                    else
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: activeSessions.map((session) {
                                          return Chip(
                                            label: Text(
                                              '${session.label} (${session.timeRange})',
                                              style: AppTextStyles.caption.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: AppColors.surfaceSoft,
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                onPressed: () => _openEditScheduleDialog(day, code),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<ScheduleSession> _activeSessionsForCode(String code) {
    final active = <ScheduleSession>[];
    for (var i = 0; i < code.length && i < ScheduleSession.all.length; i++) {
      if (code[i] == '1') {
        active.add(ScheduleSession.all[i]);
      }
    }
    return active;
  }

  void _openEditScheduleDialog(String day, String code) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return _ScheduleFormModal(
          day: day,
          initialCode: code,
          onSave: (newCode) => _saveDaySchedule(day, newCode),
        );
      },
    );
  }
}

class _ScheduleFormModal extends StatefulWidget {
  const _ScheduleFormModal({
    required this.day,
    required this.initialCode,
    required this.onSave,
  });

  final String day;
  final String initialCode;
  final ValueChanged<String> onSave;

  @override
  State<_ScheduleFormModal> createState() => _ScheduleFormModalState();
}

class _ScheduleFormModalState extends State<_ScheduleFormModal> {
  late List<int> _selectedSessions;

  @override
  void initState() {
    super.initState();
    _selectedSessions = [];
    for (var i = 0; i < widget.initialCode.length; i++) {
      if (widget.initialCode[i] == '1') {
        _selectedSessions.add(i + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Schedule - ${widget.day}'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select sessions active on this day:',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              for (final session in ScheduleSession.all)
                CheckboxListTile(
                  value: _selectedSessions.contains(session.number),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(session.label, style: AppTextStyles.bodyMedium),
                  subtitle: Text(session.timeRange, style: AppTextStyles.caption),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedSessions.add(session.number);
                      } else {
                        _selectedSessions.remove(session.number);
                      }
                      _selectedSessions.sort();
                    });
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save',
          onPressed: () {
            final buffer = StringBuffer();
            for (var i = 1; i <= 6; i++) {
              buffer.write(_selectedSessions.contains(i) ? '1' : '0');
            }
            widget.onSave(buffer.toString());
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
