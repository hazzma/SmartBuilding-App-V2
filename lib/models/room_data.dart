// EDIT_TARGET: lib/models/room_data.dart
// EDIT_PURPOSE: Holds classroom status and sensor metrics received from MQTT topics
// EDIT_REASON: Standardizes status evaluations (presence, alerts, AC parameters) for all screens
class RoomData {
  const RoomData({
    required this.room,
    this.temp,
    this.co2,
    this.lux,
    this.human,
    this.led,
    this.projector,
    this.ac,
    this.alert,
    this.active,
    this.acRaw,
    this.acPower,
    this.acTemp,
    this.acFan,
    this.acSwing,
  });

  final String room;
  final double? temp;
  final double? co2;
  final double? lux;
  final bool? human;
  final bool? led;
  final bool? projector;
  final bool? ac;
  final dynamic alert;
  final bool? active;

  final String? acRaw;
  final bool? acPower;
  final int? acTemp;
  final int? acFan;
  final int? acSwing;

  bool get hasAlert {
    if (alert == null) return false;
    if (alert is bool) return alert as bool;
    if (alert is num) return alert != 0;
    final str = alert.toString().trim();
    return str.isNotEmpty &&
        str != '0' &&
        str != 'false' &&
        !RegExp(r'^0+$').hasMatch(str);
  }

  bool get isActive => active == true;
  bool get isOccupied => human == true;

  bool hasAlertFor(String field) {
    final flags = alertFlags;
    if (flags.isEmpty) {
      return false;
    }
    if (flags.contains('general')) {
      return const {
        'temp',
        'co2',
        'lux',
        'human',
        'led',
        'projector',
        'ac',
      }.contains(field);
    }
    return flags.contains(field);
  }

  Set<String> get alertFlags {
    if (!hasAlert) {
      return const <String>{};
    }

    final text = alert.toString().trim().toLowerCase();
    if (text == 'true') {
      return const {'general'};
    }

    final decimalMask = _decimalAlertMask(alert);
    if (decimalMask != null) {
      return _flagsFromDecimalMask(decimalMask);
    }

    final binaryDigits = text.replaceAll(RegExp(r'[^01]'), '');
    if (binaryDigits.isEmpty) {
      return const {'general'};
    }

    if (binaryDigits.length >= 8) {
      final padded = binaryDigits.padLeft(8, '0');
      return {
        if (padded[0] == '1') 'temp',
        if (padded[1] == '1') 'co2',
        if (padded[2] == '1') 'lux',
        if (padded[3] == '1') 'human',
        if (padded[4] == '1') 'led',
        if (padded[5] == '1') 'projector',
        if (padded[6] == '1') 'ac',
        if (padded[7] == '1') 'presenceOutsideSchedule',
      };
    }

    if (binaryDigits.length == 7) {
      return {
        if (binaryDigits[0] == '1') 'temp',
        if (binaryDigits[1] == '1') 'co2',
        if (binaryDigits[2] == '1') 'lux',
        if (binaryDigits[3] == '1') 'human',
        if (binaryDigits[4] == '1') 'led',
        if (binaryDigits[5] == '1') 'projector',
        if (binaryDigits[6] == '1') 'presenceOutsideSchedule',
      };
    }

    final padded = binaryDigits.padRight(6, '0');
    return {
      if (padded[0] == '1') 'temp',
      if (padded[1] == '1') 'lux',
      if (padded[2] == '1') 'human',
      if (padded[3] == '1') 'led',
      if (padded[4] == '1') 'projector',
      if (padded[5] == '1') 'ac',
    };
  }

  static int? _decimalAlertMask(dynamic value) {
    if (value is bool) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }

    final text = value.toString().trim().toLowerCase();
    if (text == 'true' || text == 'false') {
      return null;
    }

    final parsed = int.tryParse(text);
    if (parsed == null) {
      return null;
    }

    final looksLikeLegacyBinary =
        RegExp(r'^[01]{2,}$').hasMatch(text) && parsed > 255;
    return looksLikeLegacyBinary ? null : parsed;
  }

  static Set<String> _flagsFromDecimalMask(int mask) {
    return {
      if ((mask & 1) != 0) 'temp',
      if ((mask & 2) != 0) 'co2',
      if ((mask & 4) != 0) 'lux',
      if ((mask & 8) != 0) 'human',
      if ((mask & 16) != 0) 'led',
      if ((mask & 32) != 0) 'projector',
      if ((mask & 64) != 0) 'ac',
      if ((mask & 128) != 0) 'presenceOutsideSchedule',
    };
  }

  List<String> get alertLabels {
    final flags = alertFlags;
    if (flags.contains('general')) {
      return const ['General alert'];
    }
    return [
      if (flags.contains('temp')) 'Temperature error',
      if (flags.contains('co2')) 'CO2 error',
      if (flags.contains('lux')) 'Lux error',
      if (flags.contains('human')) 'Presence error',
      if (flags.contains('led')) 'LED error',
      if (flags.contains('projector')) 'Projector error',
      if (flags.contains('ac')) 'AC error',
      if (flags.contains('presenceOutsideSchedule'))
        'Presence outside schedule',
    ];
  }

  String get acDisplay {
    if (acPower == null) return '-';
    if (acPower == false) return 'off';

    if (acTemp != null && acFan != null) {
      final fanLabel = switch (acFan) {
        0 => 'Auto',
        1 => 'Low',
        2 => 'Medium',
        3 => 'High',
        4 => 'Quiet',
        5 => 'Turbo',
        _ => 'Auto',
      };
      return '$acTemp°C, $fanLabel';
    }
    return 'on';
  }

  String valueLabel(String field) {
    return switch (field) {
      'temp' => temp == null ? '-' : '${temp!.toStringAsFixed(1)} C',
      'co2' => co2 == null ? '-' : '${co2!.toStringAsFixed(0)} ppm',
      'lux' => lux == null ? '-' : '${lux!.toStringAsFixed(0)} lx',
      'human' || 'presense' || 'presence' => _yesNoLabel(human),
      'led' => _boolLabel(led),
      'projector' => _boolLabel(projector),
      'ac' => acDisplay,
      'alert' => _boolLabel(_asBool(alert)),
      'active' => _boolLabel(active),
      _ => '-',
    };
  }

  static String _boolLabel(bool? value) {
    return switch (value) {
      true => 'on',
      false => 'off',
      null => '-',
    };
  }

  static String _yesNoLabel(bool? value) {
    return switch (value) {
      true => 'yes',
      false => 'no',
      null => '-',
    };
  }

  static double? _asDouble(dynamic value) {
    if (value is num) {
      if (value == -1) return null;
      return value.toDouble();
    }
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == -1) return null;
    return parsed;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      if (value == -1) return null;
      return value != 0;
    }
    final text = value?.toString().trim().toLowerCase();
    if (text == null || text.isEmpty || text == '-1') {
      return null;
    }
    if (text == '1' || text == 'true' || text == 'on' || text == 'yes') {
      return true;
    }
    if (text == '0' || text == 'false' || text == 'off' || text == 'no') {
      return false;
    }
    return null;
  }

  RoomData copyWith({
    String? room,
    double? temp,
    double? co2,
    double? lux,
    bool? human,
    bool? led,
    bool? projector,
    bool? ac,
    dynamic alert,
    bool? active,
    String? acRaw,
    bool? acPower,
    int? acTemp,
    int? acFan,
    int? acSwing,
  }) {
    return RoomData(
      room: room ?? this.room,
      temp: temp ?? this.temp,
      co2: co2 ?? this.co2,
      lux: lux ?? this.lux,
      human: human ?? this.human,
      led: led ?? this.led,
      projector: projector ?? this.projector,
      ac: ac ?? this.ac,
      alert: alert ?? this.alert,
      active: active ?? this.active,
      acRaw: acRaw ?? this.acRaw,
      acPower: acPower ?? this.acPower,
      acTemp: acTemp ?? this.acTemp,
      acFan: acFan ?? this.acFan,
      acSwing: acSwing ?? this.acSwing,
    );
  }

  factory RoomData.fromFieldValue(RoomData? current, String field, dynamic rawValue) {
    final roomName = current?.room ?? '';
    final map = <String, dynamic>{
      'temp': current?.temp,
      'co2': current?.co2,
      'lux': current?.lux,
      'human': current?.human,
      'led': current?.led,
      'projector': current?.projector,
      'ac': current?.acRaw,
      'alert': current?.alert,
      'active': current?.active,
    };

    map[field.toLowerCase()] = rawValue;

    final acVal = map['ac'];
    bool? acPower;
    int? acTemp;
    int? acFan;
    int? acSwing;
    if (acVal != null) {
      final acStr = acVal.toString().trim();
      final acInt = int.tryParse(acStr);
      if (acStr.contains('/')) {
        final parts = acStr.split('/');
        acPower = parts[0] == '01' || parts[0] == '1';
        acTemp = int.tryParse(parts[1]);
        acFan = int.tryParse(parts[2]);
        acSwing = int.tryParse(parts[3]);
      } else if (acInt != null && acStr.length >= 5) {
        final padded = acStr.padLeft(8, '0');
        acPower = padded.substring(0, 2) == '01';
        acTemp = int.tryParse(padded.substring(2, 4));
        acFan = int.tryParse(padded.substring(4, 6));
        acSwing = int.tryParse(padded.substring(6, 8));
      } else {
        acPower = _asBool(acVal);
      }
    }

    return RoomData(
      room: roomName,
      temp: _asDouble(map['temp']),
      co2: _asDouble(map['co2']),
      lux: _asDouble(map['lux']),
      human: _asBool(map['presence'] ?? map['human'] ?? map['motion']),
      led: _asBool(map['led']),
      projector: _asBool(map['projector']),
      ac: acPower,
      alert: map['alert'],
      active: _asBool(map['active']),
      acRaw: acVal?.toString(),
      acPower: acPower,
      acTemp: acTemp,
      acFan: acFan,
      acSwing: acSwing,
    );
  }
}

class HomeSummary {
  const HomeSummary({
    required this.totalClasses,
    required this.activeClasses,
    required this.alertCount,
  });

  final int totalClasses;
  final int activeClasses;
  final int alertCount;
}

class OngoingClass {
  const OngoingClass({
    required this.room,
    required this.session,
  });

  final String room;
  final ScheduleSession session;
}

class ScheduleSession {
  const ScheduleSession({
    required this.number,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final int number;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  String get label => 'Session $number';

  String get timeRange {
    String time(int hour, int minute) {
      return '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
    }

    return '${time(startHour, startMinute)} - ${time(endHour, endMinute)}';
  }

  bool contains(DateTime dateTime) {
    final start = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      startHour,
      startMinute,
    );
    final end = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      endHour,
      endMinute,
    );
    return !dateTime.isBefore(start) && dateTime.isBefore(end);
  }

  static const List<ScheduleSession> all = [
    ScheduleSession(
      number: 1,
      startHour: 7,
      startMinute: 20,
      endHour: 9,
      endMinute: 0,
    ),
    ScheduleSession(
      number: 2,
      startHour: 9,
      startMinute: 20,
      endHour: 11,
      endMinute: 0,
    ),
    ScheduleSession(
      number: 3,
      startHour: 11,
      startMinute: 20,
      endHour: 13,
      endMinute: 0,
    ),
    ScheduleSession(
      number: 4,
      startHour: 13,
      startMinute: 20,
      endHour: 15,
      endMinute: 0,
    ),
    ScheduleSession(
      number: 5,
      startHour: 15,
      startMinute: 20,
      endHour: 17,
      endMinute: 0,
    ),
    ScheduleSession(
      number: 6,
      startHour: 17,
      startMinute: 20,
      endHour: 19,
      endMinute: 0,
    ),
  ];

  static ScheduleSession? at(DateTime dateTime) {
    for (final session in all) {
      if (session.contains(dateTime)) {
        return session;
      }
    }
    return null;
  }
}
