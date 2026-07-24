// EDIT_TARGET: lib/services/mqtt_service.dart
// EDIT_PURPOSE: Real-time EMQX MQTT communication and dynamic room discovery
// EDIT_REASON: Allows classrooms and their parameters to sync instantly via MQTT TLS on port 8883
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/class_room_config.dart';
import '../models/room_data.dart';

class MqttService extends ChangeNotifier {
  MqttService() {
    loadSettings();
  }

  // MQTT parameters
  String host = 'wd5de919.ala.asia-southeast1.emqxsl.com';
  int port = 8883;
  String username = 'Hansganteng';
  String password = '12345678';

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _subscription;
  bool _isConnecting = false;

  // Active state data cache
  final List<String> _discoveredRoomNames = [];
  final Map<String, RoomData> _roomData = {};
  final Map<String, Map<String, String>> _schedules = {};

  bool get isConnecting => _isConnecting;
  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  List<ClassRoomConfig> get classrooms {
    return _discoveredRoomNames.map(_classroomFromRoomName).toList();
  }

  Map<String, RoomData> get roomIndicators => _roomData;

  RoomData? getRoomDetails(String roomName) => _roomData[roomName];

  // Dynamically constructs metadata from room name (e.g. "HD01" -> Building H, Floor 0)
  ClassRoomConfig _classroomFromRoomName(String room) {
    final normalized = room.trim();
    return ClassRoomConfig(
      id: 'room-${normalized.toLowerCase()}',
      className: normalized,
      displayName: 'Class $normalized',
      buildingName: _buildingNameFromRoom(normalized),
      floorName: _floorNameFromRoom(normalized),
    );
  }

  String _buildingNameFromRoom(String room) {
    if (room.isEmpty) return 'Building';
    return 'Building ${room[0].toUpperCase()}';
  }

  String _floorNameFromRoom(String room) {
    if (room.length < 2) return 'Floor 1';
    final floor = int.tryParse(room[1]);
    return floor == null ? 'Floor 1' : 'Floor $floor';
  }

  Future<HomeSummary> loadHomeSummary() async {
    final ongoing = await loadOngoingClasses();
    return HomeSummary(
      totalClasses: _discoveredRoomNames.length,
      activeClasses: ongoing.length,
      alertCount: _roomData.values.where((r) => r.hasAlert).length,
    );
  }

  Future<List<OngoingClass>> loadOngoingClasses() async {
    final now = DateTime.now();
    final session = ScheduleSession.at(now);
    if (session == null) {
      return const [];
    }

    final dayName = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'sunday',
    ][now.weekday - 1];

    final ongoing = <OngoingClass>[];
    for (final room in _discoveredRoomNames) {
      final schedule = getSchedule(room);
      final dayCode = schedule[dayName] ?? '000000';
      final sessionIndex = session.number - 1;
      if (dayCode.length > sessionIndex && dayCode[sessionIndex] == '1') {
        ongoing.add(OngoingClass(room: room, session: session));
      }
    }
    ongoing.sort((a, b) => a.room.compareTo(b.room));
    return ongoing;
  }

  Map<String, String> getSchedule(String roomName) {
    return _schedules[roomName] ??
        {
          'Monday': '000000',
          'Tuesday': '000000',
          'Wednesday': '000000',
          'Thursday': '000000',
          'Friday': '000000',
          'Saturday': '000000',
          'sunday': '000000',
        };
  }

  Future<void> saveSchedule(String roomName, String day, String code) async {
    final roomSchedule = _schedules.putIfAbsent(
      roomName,
      () => {
        'Monday': '000000',
        'Tuesday': '000000',
        'Wednesday': '000000',
        'Thursday': '000000',
        'Friday': '000000',
        'Saturday': '000000',
        'sunday': '000000',
      },
    );
    roomSchedule[day] = code;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('schedule_$roomName', jsonEncode(roomSchedule));

    // EDIT_TARGET: lib/services/mqtt_service.dart (saveSchedule)
    // EDIT_PURPOSE: Format control topic without prefix
    // EDIT_REASON: Standard room/control/schedule format
    // Publish command
    final controlTopic = '$roomName/control/schedule';
    final payload = jsonEncode({'day': day, 'code': code});
    publishRaw(controlTopic, payload, retain: false);

    notifyListeners();
  }

  // Core Connection Method
  Future<void> connect() async {
    if (isConnected || _isConnecting) return;

    _isConnecting = true;
    notifyListeners();

    try {
      await disconnect();

      final clientId = 'smartclass-app-${DateTime.now().millisecondsSinceEpoch}';
      final client = MqttServerClient.withPort(host, clientId, port);
      client.logging(on: false);
      client.keepAlivePeriod = 20;
      client.secure = true;
      client.onBadCertificate = (dynamic cert) => true;
      client.onDisconnected = _onDisconnected;

      _client = client;

      debugPrint('Connecting to MQTT: $host:$port with client $clientId...');
      await client.connect(
        username.isEmpty ? null : username,
        password.isEmpty ? null : password,
      );

      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        final status = client.connectionStatus?.returnCode ?? 'unknown';
        client.disconnect();
        throw StateError('MQTT connection state is not connected: $status');
      }

      // EDIT_TARGET: lib/services/mqtt_service.dart (connect)
      // EDIT_PURPOSE: Subscribe directly to wildcard topic without prefix
      // EDIT_REASON: Direct room/data/field structure
      // Subscribe to all rooms state
      final subscriptionTopic = '+/data/+';
      debugPrint('MQTT connected! Subscribing to: $subscriptionTopic');
      client.subscribe(subscriptionTopic, MqttQos.atLeastOnce);

      _subscription = client.updates?.listen((messages) {
        for (final message in messages) {
          final publishMessage = message.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            publishMessage.payload.message,
          );
          _handleMessage(message.topic, payload);
        }
      });
    } catch (e) {
      debugPrint('MQTT connection error: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  void _onDisconnected() {
    debugPrint('MQTT client has disconnected.');
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _client?.disconnect();
    _client = null;
    notifyListeners();
  }

  // EDIT_TARGET: lib/services/mqtt_service.dart (_handleMessage)
  // EDIT_PURPOSE: Simplify topic parsing directly starting from index 0
  // EDIT_REASON: Decoupled prefix requirements simplify extraction to parts[0], parts[1], parts[2]
  void _handleMessage(String topic, String payload) {
    debugPrint('MQTT message: $topic -> $payload');
    final topicParts = topic.split('/');

    if (topicParts.length >= 3) {
      final roomName = topicParts[0];
      final type = topicParts[1]; // "data" or "control"
      final field = topicParts.sublist(2).join('/');

      if (type == 'data') {
        _updateRoomValue(roomName, field, payload);
      }
    }
  }

  void _updateRoomValue(String roomName, String field, String payload) {
    if (roomName.trim().isEmpty) return;

    if (!_discoveredRoomNames.contains(roomName)) {
      _discoveredRoomNames.add(roomName);
      _discoveredRoomNames.sort();
      _saveDiscoveredRooms();
    }

    final currentData = _roomData[roomName] ?? RoomData(room: roomName);
    dynamic rawValue = payload;
    final numValue = num.tryParse(payload);
    if (numValue != null) {
      rawValue = numValue;
    }

    final updatedData = RoomData.fromFieldValue(currentData, field, rawValue);
    _roomData[roomName] = updatedData;
    debugPrint('MqttService: Room $roomName field $field updated to $rawValue. notifyListeners() called.');
    notifyListeners();
  }

  // EDIT_TARGET: lib/services/mqtt_service.dart (publishRaw)
  // EDIT_PURPOSE: Add optional retain parameter and pass it to client.publishMessage
  // EDIT_REASON: Allows disabling retention dynamically for control/command packets
  void publishRaw(String topic, String payload, {bool retain = false}) {
    final client = _client;
    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('Cannot publish: MQTT not connected.');
      return;
    }
    final builder = MqttClientPayloadBuilder()..addString(payload);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!,
        retain: retain);
  }

  // EDIT_TARGET: lib/services/mqtt_service.dart (publishControl)
  // EDIT_PURPOSE: Explicitly pass retain: false to control message publishes
  // EDIT_REASON: Command events should not be retained by the broker to avoid stale state issues on reconnection
  void publishControl(String roomName, String field, dynamic value) {
    // Determine published payload shape
    String payloadStr;
    if (value is bool) {
      payloadStr = value ? '1' : '0';
    } else {
      payloadStr = value.toString();
    }

    // EDIT_TARGET: lib/services/mqtt_service.dart (publishControl)
    // EDIT_PURPOSE: Remove prefix prefixing from control topic publishing
    // EDIT_REASON: Topics should be room/control/field
    final topic = '$roomName/control/$field';
    debugPrint('Publishing control: $topic -> $payloadStr');
    publishRaw(topic, payloadStr, retain: false);

    // Optimistically update local data cache
    final currentData = _roomData[roomName] ?? RoomData(room: roomName);
    final updatedData = RoomData.fromFieldValue(currentData, field, value);
    _roomData[roomName] = updatedData;
    notifyListeners();
  }

  // EDIT_TARGET: lib/services/mqtt_service.dart (publishCampusLights)
  // EDIT_PURPOSE: Remove prefix prefixing from campus light led control topic
  // EDIT_REASON: Topic should format as room/control/led
  void publishCampusLights(bool turnOn) {
    final valueStr = turnOn ? '1' : '0';
    for (final room in _discoveredRoomNames) {
      final topic = '$room/control/led';
      debugPrint('Publishing campus lights: $topic -> $valueStr');
      publishRaw(topic, valueStr, retain: false);

      final currentData = _roomData[room] ?? RoomData(room: room);
      _roomData[room] = RoomData.fromFieldValue(currentData, 'led', turnOn);
    }
    notifyListeners();
  }

  // Load and save local persistence helpers
  Future<void> loadSettings() async {
    // EDIT_TARGET: lib/services/mqtt_service.dart (loadSettings)
    // EDIT_PURPOSE: Remove prefix setting loader
    // EDIT_REASON: Removed support for custom prefixes
    final prefs = await SharedPreferences.getInstance();
    host = prefs.getString('mqtt_host') ?? 'wd5de919.ala.asia-southeast1.emqxsl.com';
    port = prefs.getInt('mqtt_port') ?? 8883;
    username = prefs.getString('mqtt_username') ?? 'Hansganteng';
    password = prefs.getString('mqtt_password') ?? '12345678';

    final roomsList = prefs.getStringList('discovered_rooms');
    if (roomsList != null && roomsList.isNotEmpty) {
      _discoveredRoomNames
        ..clear()
        ..addAll(roomsList)
        ..sort();
    } else {
      _discoveredRoomNames
        ..clear()
        ..addAll(['HD01', 'L1D'])
        ..sort();
    }

    await _loadSchedules();
    notifyListeners();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    for (final room in _discoveredRoomNames) {
      final jsonStr = prefs.getString('schedule_$room');
      if (jsonStr != null) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(jsonStr));
          _schedules[room] =
              map.map((key, value) => MapEntry(key, value.toString()));
        } catch (e) {
          debugPrint('Error loading schedule for $room: $e');
        }
      }
    }
  }

  Future<void> _saveDiscoveredRooms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('discovered_rooms', _discoveredRoomNames);
  }

  // EDIT_TARGET: lib/services/mqtt_service.dart (saveSettings)
  // EDIT_PURPOSE: Remove prefix parameter from save settings function signature and body
  // EDIT_REASON: Custom prefix settings are no longer supported
  Future<void> saveSettings({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    this.host = host;
    this.port = port;
    this.username = username;
    this.password = password;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_host', host);
    await prefs.setInt('mqtt_port', port);
    await prefs.setString('mqtt_username', username);
    await prefs.setString('mqtt_password', password);

    notifyListeners();
  }
}
