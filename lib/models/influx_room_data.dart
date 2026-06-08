// EDIT_TARGET: lib/models/influx_room_data.dart
// EDIT_PURPOSE: Holds latest classroom values loaded from InfluxDB.
// EDIT_REASON: UI screens need typed access to room tag data without owning query details.

class InfluxRoomData {
  const InfluxRoomData({
    required this.room,
    this.temp,
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
    return str.isNotEmpty && str != '0' && str != 'false' && !RegExp(r'^0+$').hasMatch(str);
  }

  bool get isActive => active == true;
  bool get isOccupied => human == true;

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

  factory InfluxRoomData.fromValues(
    String room,
    Map<String, dynamic> values,
  ) {
    final acVal = values['ac'];
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

    return InfluxRoomData(
      room: room,
      temp: _asDouble(values['temp']),
      lux: _asDouble(values['lux']),
      human: _asBool(values['presence'] ?? values['human'] ?? values['motion']),
      led: _asBool(values['led']),
      projector: _asBool(values['projector']),
      ac: acPower,
      alert: values['alert'],
      active: _asBool(values['active']),
      acRaw: acVal?.toString(),
      acPower: acPower,
      acTemp: acTemp,
      acFan: acFan,
      acSwing: acSwing,
    );
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
}

class InfluxHomeSummary {
  const InfluxHomeSummary({
    required this.totalClasses,
    required this.activeClasses,
    required this.alertCount,
  });

  final int totalClasses;
  final int activeClasses;
  final int alertCount;
}
