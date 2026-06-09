// EDIT_TARGET: test/influx_room_data_test.dart
// EDIT_PURPOSE: Verifies ongoing-session timing and per-field alert decoding
// EDIT_REASON: Home activity and classroom warning icons depend on stable mappings

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_building_app/models/influx_room_data.dart';

void main() {
  test('finds the current predefined session', () {
    final session = InfluxScheduleSession.at(
      DateTime(2026, 6, 9, 13, 30),
    );

    expect(session?.number, 4);
    expect(session?.timeRange, '13:20 - 15:00');
  });

  test('returns no session during the break between sessions', () {
    final session = InfluxScheduleSession.at(
      DateTime(2026, 6, 9, 13, 10),
    );

    expect(session, isNull);
  });

  test('maps compact alert flags to individual sensors and controls', () {
    final room = InfluxRoomData.fromValues('L1D', {
      'alert': '100101',
    });

    expect(room.hasAlertFor('temp'), isTrue);
    expect(room.hasAlertFor('lux'), isFalse);
    expect(room.hasAlertFor('human'), isFalse);
    expect(room.hasAlertFor('led'), isTrue);
    expect(room.hasAlertFor('projector'), isFalse);
    expect(room.hasAlertFor('ac'), isTrue);
  });

  test('keeps legacy eight-bit alert positions compatible', () {
    final room = InfluxRoomData.fromValues('L1D', {
      'alert': '00100010',
    });

    expect(room.hasAlertFor('lux'), isTrue);
    expect(room.hasAlertFor('ac'), isTrue);
    expect(room.hasAlertFor('temp'), isFalse);
  });
}
