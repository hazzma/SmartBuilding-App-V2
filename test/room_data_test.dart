// EDIT_TARGET: test/room_data_test.dart
// EDIT_PURPOSE: Verifies ongoing-session timing and per-field alert decoding for RoomData
// EDIT_REASON: Ensures UI badges and warning icons correctly map to parsed sensor payloads
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_building_app/models/room_data.dart';

void main() {
  test('finds the current predefined session', () {
    final session = ScheduleSession.at(
      DateTime(2026, 6, 9, 13, 30),
    );

    expect(session?.number, 4);
    expect(session?.timeRange, '13:20 - 15:00');
  });

  test('returns no session during the break between sessions', () {
    final session = ScheduleSession.at(
      DateTime(2026, 6, 9, 13, 10),
    );

    expect(session, isNull);
  });

  test('maps decimal alert mask values to individual widgets', () {
    final room = RoomData.fromFieldValue(null, 'alert', 80);

    expect(room.hasAlertFor('temp'), isFalse);
    expect(room.hasAlertFor('lux'), isFalse);
    expect(room.hasAlertFor('human'), isFalse);
    expect(room.hasAlertFor('led'), isTrue);
    expect(room.hasAlertFor('projector'), isFalse);
    expect(room.hasAlertFor('ac'), isTrue);
  });

  test('does not treat decimal mask one as a general alert', () {
    final room = RoomData.fromFieldValue(null, 'alert', 1);

    expect(room.hasAlertFor('temp'), isTrue);
    expect(room.hasAlertFor('lux'), isFalse);
    expect(room.hasAlertFor('human'), isFalse);
    expect(room.hasAlertFor('led'), isFalse);
    expect(room.hasAlertFor('projector'), isFalse);
    expect(room.hasAlertFor('ac'), isFalse);
  });

  test('maps zero alert mask to no sensor or actuator alerts', () {
    final room = RoomData.fromFieldValue(null, 'alert', 0);

    expect(room.hasAlert, isFalse);
    expect(room.alertFlags, isEmpty);
    expect(room.hasAlertFor('temp'), isFalse);
    expect(room.hasAlertFor('led'), isFalse);
    expect(room.hasAlertFor('ac'), isFalse);
  });

  test('keeps legacy eight-bit alert positions compatible', () {
    final room = RoomData.fromFieldValue(null, 'alert', '00100010');

    expect(room.hasAlertFor('lux'), isTrue);
    expect(room.hasAlertFor('ac'), isTrue);
    expect(room.hasAlertFor('temp'), isFalse);
  });
}
