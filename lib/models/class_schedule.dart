// EDIT_TARGET: class_schedule.dart
// EDIT_PURPOSE: Defines one-time or weekly classroom schedules.
// EDIT_REASON: FSD V2 Schedule tab stores schedule entries by classRoomId.

class ClassSchedule {
  const ClassSchedule({
    required this.id,
    required this.classRoomId,
    required this.title,
    this.date,
    this.daysOfWeek = const <int>[],
    required this.sessionNumbers,
    this.automationEnabled = true,
  });

  final String id;
  final String classRoomId;
  final String title;
  final DateTime? date;
  final List<int> daysOfWeek;
  final List<int> sessionNumbers;
  final bool automationEnabled;

  String get startTime => ScheduleSession.byNumber(sessionNumbers.first).start;

  String get endTime => ScheduleSession.byNumber(sessionNumbers.last).end;

  Map<String, int> get sessionFlags {
    return {
      for (var number = 1; number <= ScheduleSession.all.length; number++)
        'session$number': sessionNumbers.contains(number) ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classRoomId': classRoomId,
      'title': title,
      'date': date?.toIso8601String(),
      'daysOfWeek': daysOfWeek,
      'sessionNumbers': sessionNumbers,
      ...sessionFlags,
      'automationEnabled': automationEnabled,
    };
  }

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    final sessionNumbers = _sessionNumbersFromJson(json);

    return ClassSchedule(
      id: json['id'] as String? ?? '',
      classRoomId: json['classRoomId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>? ?? const [])
          .map((item) => item as int)
          .toList(),
      sessionNumbers: sessionNumbers.isEmpty ? const [1] : sessionNumbers,
      automationEnabled: json['automationEnabled'] as bool? ?? true,
    );
  }

  static List<int> _sessionNumbersFromJson(Map<String, dynamic> json) {
    final storedNumbers = (json['sessionNumbers'] as List<dynamic>? ?? const [])
        .map((item) => item as int)
        .where((number) => number >= 1 && number <= ScheduleSession.all.length)
        .toList();
    if (storedNumbers.isNotEmpty) {
      storedNumbers.sort();
      return storedNumbers;
    }

    final flags = [
      for (var number = 1; number <= ScheduleSession.all.length; number++)
        if (json['session$number'] == 1 || json['session$number'] == true)
          number,
    ];
    if (flags.isNotEmpty) {
      return flags;
    }

    final oldStartTime = json['startTime'] as String?;
    final oldEndTime = json['endTime'] as String?;
    return [
      for (final session in ScheduleSession.all)
        if (session.start == oldStartTime || session.end == oldEndTime)
          session.number,
    ];
  }
}

class ScheduleSession {
  const ScheduleSession({
    required this.number,
    required this.start,
    required this.end,
  });

  final int number;
  final String start;
  final String end;

  String get label => 'Session $number';
  String get timeRange => '$start - $end';

  static const List<ScheduleSession> all = [
    ScheduleSession(number: 1, start: '07:20', end: '09:00'),
    ScheduleSession(number: 2, start: '09:20', end: '11:00'),
    ScheduleSession(number: 3, start: '11:20', end: '13:00'),
    ScheduleSession(number: 4, start: '13:20', end: '15:00'),
    ScheduleSession(number: 5, start: '15:20', end: '17:00'),
    ScheduleSession(number: 6, start: '17:20', end: '19:00'),
  ];

  static ScheduleSession byNumber(int number) {
    return all.firstWhere(
      (session) => session.number == number,
      orElse: () => all.first,
    );
  }
}
