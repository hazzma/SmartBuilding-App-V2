// EDIT_TARGET: lib/services/influxdb_service.dart
// EDIT_PURPOSE: Provides focused InfluxDB 2.x read queries for SmartClass screens.
// EDIT_REASON: Pages should request only the room data they need when opened or interacted with.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/influx_room_data.dart';

class InfluxDbService {
  InfluxDbService({
    this.url = 'http://10.194.151.250:8086',
    this.token =
        'T60ZU0IiObzr_2miqrya32DaAdl7Rer1MQv1pF_Xg0fRE32K8zPGn8LI7JsdblJ_-s13qi80vux87cswsAdxzw==',
    this.bucket = 'SmartClass',
    this.measurement = 'classroom',
  });

  final String url;
  final String token;
  final String bucket;
  final String measurement;

  String? _org;

  Future<InfluxHomeSummary> loadHomeSummary() async {
    final rooms = await loadRooms();
    final indicators = await loadRoomIndicators();
    return InfluxHomeSummary(
      totalClasses: rooms.length,
      activeClasses: indicators.values.where((room) => room.isActive).length,
      alertCount: indicators.values.where((room) => room.hasAlert).length,
    );
  }

  Future<List<String>> loadRooms() async {
    final rows = await _query('''
import "influxdata/influxdb/schema"
schema.tagValues(
  bucket: "$bucket",
  tag: "room",
  predicate: (r) => r._measurement == "$measurement",
  start: -30d,
)
''');

    final rooms = rows
        .map((row) => row['_value'] ?? row['room'])
        .whereType<String>()
        .where((room) => room.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return rooms;
  }

  Future<Map<String, InfluxRoomData>> loadRoomIndicators() {
    return _loadLatestFieldsByRoom(const ['human', 'presence', 'motion', 'alert', 'active']);
  }

  Future<InfluxRoomData?> loadRoomDetails(String room) async {
    final rooms = await _loadLatestFieldsByRoom(
      const ['temp', 'lux', 'human', 'presence', 'motion', 'led', 'projector', 'ac', 'alert', 'active'],
      room: room,
    );
    return rooms[room];
  }

  Future<Map<String, InfluxRoomData>> _loadLatestFieldsByRoom(
    List<String> fields, {
    String? room,
  }) async {
    final fieldFilter = fields.map((field) => 'r._field == "$field"').join(' or ');
    final roomFilter = room == null ? '' : '  |> filter(fn: (r) => r.room == "${_escapeFlux(room)}")\n';
    final rows = await _query('''
from(bucket: "$bucket")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "$measurement")
  |> filter(fn: (r) => $fieldFilter)
$roomFilter  |> group(columns: ["room", "_field"])
  |> last()
''');

    final valuesByRoom = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final roomName = row['room'];
      final field = row['_field'];
      if (roomName == null || field == null) {
        continue;
      }
      valuesByRoom.putIfAbsent(roomName, () => <String, dynamic>{})[field] =
          _parseValue(row['_value']);
    }

    return {
      for (final entry in valuesByRoom.entries)
        entry.key: InfluxRoomData.fromValues(entry.key, entry.value),
    };
  }

  Future<List<Map<String, String>>> _query(String flux) async {
    final org = await _resolveOrg();
    debugPrint('Using InfluxDB Organization: $org');
    final queryUri = _baseUri().replace(
      path: '${_baseUri().path}/api/v2/query'.replaceAll('//', '/'),
      queryParameters: {'org': org},
    );
    final client = HttpClient();
    try {
      final request = await client.postUrl(queryUri);
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Token $token')
        ..set(HttpHeaders.acceptHeader, 'application/csv')
        ..set(HttpHeaders.contentTypeHeader, 'application/vnd.flux');
      request.write(flux);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      debugPrint('Raw InfluxDB response:\n$body');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw InfluxDbException('InfluxDB query failed: ${response.statusCode} $body');
      }
      return _parseAnnotatedCsv(body);
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _resolveOrg() async {
    if (_org != null) {
      return _org!;
    }

    final orgUri = _baseUri().replace(
      path: '${_baseUri().path}/api/v2/orgs'.replaceAll('//', '/'),
    );
    final client = HttpClient();
    try {
      final request = await client.getUrl(orgUri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Token $token');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw InfluxDbException('InfluxDB org lookup failed: ${response.statusCode} $body');
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final orgs = decoded['orgs'] as List<dynamic>? ?? const [];
      if (orgs.isEmpty) {
        throw const InfluxDbException('No InfluxDB orgs are available for this token.');
      }
      final firstOrg = orgs.first as Map<String, dynamic>;
      _org = (firstOrg['name'] ?? firstOrg['id']).toString();
      debugPrint('Resolved InfluxDB Organization: $_org');
      return _org!;
    } finally {
      client.close(force: true);
    }
  }

  Uri _baseUri() {
    final uri = Uri.parse(url);
    if (!kIsWeb && Platform.isAndroid && uri.host == 'localhost') {
      return uri.replace(host: '10.0.2.2');
    }
    return uri;
  }

  List<Map<String, String>> _parseAnnotatedCsv(String body) {
    final lines = const LineSplitter().convert(body);
    List<String>? header;
    final rows = <Map<String, String>>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }
      final columns = _parseCsvLine(line);
      if (columns.isEmpty || columns.first.startsWith('#')) {
        continue;
      }
      if (columns.contains('_value')) {
        header = columns;
        continue;
      }
      if (header == null || columns.length < header.length) {
        continue;
      }

      final row = <String, String>{};
      for (var index = 0; index < header.length; index++) {
        row[header[index]] = columns[index];
      }
      rows.add(row);
    }

    return rows;
  }

  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < line.length; index++) {
      final char = line[index];
      if (char == '"') {
        final nextIsQuote = index + 1 < line.length && line[index + 1] == '"';
        if (inQuotes && nextIsQuote) {
          buffer.write('"');
          index++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    values.add(buffer.toString());
    return values;
  }

  dynamic _parseValue(String? value) {
    if (value == null) {
      return null;
    }
    final number = num.tryParse(value);
    if (number != null) {
      return number;
    }
    return value;
  }

  Future<void> writeRoomField(String room, String field, dynamic value) async {
    final org = await _resolveOrg();
    final writeUri = _baseUri().replace(
      path: '${_baseUri().path}/api/v2/write'.replaceAll('//', '/'),
      queryParameters: {
        'org': org,
        'bucket': bucket,
      },
    );

    String valueStr;
    if (value is bool) {
      valueStr = value ? '1' : '0';
    } else if (value is String) {
      if (field == 'ac') {
        final escaped = value.replaceAll('"', r'\"');
        valueStr = '"$escaped"';
      } else {
        final isDigits = RegExp(r'^\d+$').hasMatch(value);
        if (isDigits) {
          valueStr = int.parse(value).toString();
        } else {
          final escaped = value.replaceAll('"', r'\"');
          valueStr = '"$escaped"';
        }
      }
    } else {
      valueStr = value.toString();
    }

    final line = 'classroom,room=${_escapeFluxTag(room)} $field=$valueStr';

    final client = HttpClient();
    try {
      final request = await client.postUrl(writeUri);
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Token $token')
        ..set(HttpHeaders.contentTypeHeader, 'text/plain; charset=utf-8');
      request.write(line);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw InfluxDbException('InfluxDB write failed: ${response.statusCode} $body');
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, String>> loadClassroomSchedule(String room) async {
    final rows = await _query('''
from(bucket: "$bucket")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "classroom_schedule")
  |> filter(fn: (r) => r.room == "${_escapeFlux(room)}")
  |> last()
''');

    final result = <String, String>{
      'Monday': '000000',
      'Tuesday': '000000',
      'Wednesday': '000000',
      'Thursday': '000000',
      'Friday': '000000',
      'Saturday': '000000',
      'sunday': '000000',
    };

    for (final row in rows) {
      final field = row['_field'];
      final value = row['_value'];
      if (field != null && value != null) {
        final matchingKey = result.keys.firstWhere(
          (k) => k.toLowerCase() == field.toLowerCase(),
          orElse: () => field,
        );
        result[matchingKey] = _normalizeScheduleCode(value);
      }
    }
    return result;
  }

  String _normalizeScheduleCode(dynamic value) {
    if (value == null) return '000000';
    var str = value.toString().trim();
    if (str.contains('.')) {
      str = str.split('.').first;
    }
    if (str.length < 6) {
      return str.padLeft(6, '0');
    }
    return str;
  }

  Future<void> writeClassroomSchedule(String room, String dayOfWeek, String code) async {
    final org = await _resolveOrg();
    final writeUri = _baseUri().replace(
      path: '${_baseUri().path}/api/v2/write'.replaceAll('//', '/'),
      queryParameters: {
        'org': org,
        'bucket': bucket,
      },
    );

    final intCode = int.tryParse(code) ?? 0;
    final line = 'classroom_schedule,room=${_escapeFluxTag(room)} $dayOfWeek=$intCode';

    final client = HttpClient();
    try {
      final request = await client.postUrl(writeUri);
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Token $token')
        ..set(HttpHeaders.contentTypeHeader, 'text/plain; charset=utf-8');
      request.write(line);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw InfluxDbException('InfluxDB schedule write failed: ${response.statusCode} $body');
      }
    } finally {
      client.close(force: true);
    }
  }

  String _escapeFluxTag(String value) {
    return value.replaceAll(' ', r'\ ').replaceAll(',', r'\,').replaceAll('=', r'\=');
  }

  String _escapeFlux(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll('"', r'\"');
  }
}

class InfluxDbException implements Exception {
  const InfluxDbException(this.message);

  final String message;

  @override
  String toString() => message;
}
