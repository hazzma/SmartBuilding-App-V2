import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/debug_log_entry.dart';
import '../models/device_display_config.dart';
import '../models/master_command.dart';
import '../models/master_registry_item.dart';
import '../models/master_state.dart';
import '../models/mqtt_connection_config.dart';
import '../services/config_storage.dart';
import '../services/mqtt_gateway.dart';

// EDIT_TARGET: smart_building_controller.dart
// EDIT_PURPOSE: Mengelola connection, master registry, active master, command, dan debug log.
// EDIT_REASON: FSD meminta state MQTT, registry, active master, command, dan debug dipisah dari UI.
class SmartBuildingController extends ChangeNotifier {
  SmartBuildingController({MqttGateway? mqttGateway, ConfigStorage? storage})
    : _mqttGateway = mqttGateway ?? MqttGateway(),
      _storage = storage ?? ConfigStorage() {
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
    loadSavedConfig();
  }

  final MqttGateway _mqttGateway;
  final ConfigStorage _storage;
  late final Timer _ticker;
  final Map<String, MasterRegistryItem> _registry = {};
  final Map<String, DeviceDisplayConfig> _deviceConfigs = {};
  final List<DebugLogEntry> _debugLog = [];

  MqttConnectionConfig config = const MqttConnectionConfig();
  bool isConfigLoaded = false;
  bool isConnecting = false;
  bool isConnected = false;
  String? activeMasterKey;
  String? lastRawState;
  String? lastSentCommand;
  int currentTab = 0;

  List<MasterRegistryItem> get masters {
    final items = _registry.values.toList()
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    return items;
  }

  List<MasterRegistryItem> get homeMasters {
    return masters
        .where((item) => deviceConfigFor(item.state.identityKey).showInHome)
        .toList(growable: false);
  }

  MasterState? get activeMaster =>
      activeMasterKey == null ? null : _registry[activeMasterKey!]?.state;

  MasterRegistryItem? get activeMasterRegistryItem =>
      activeMasterKey == null ? null : _registry[activeMasterKey!];

  bool get activeMasterIsStale =>
      activeMasterRegistryItem?.isStale(DateTime.now()) ?? false;

  bool get canPublishControls =>
      isConnected && activeMaster != null && !activeMasterIsStale;

  List<DebugLogEntry> get debugLog => List.unmodifiable(_debugLog);

  Map<String, DeviceDisplayConfig> get deviceConfigs =>
      Map.unmodifiable(_deviceConfigs);

  Future<void> loadSavedConfig() async {
    try {
      config = await _storage.loadMqttConfig() ?? config;
      _deviceConfigs
        ..clear()
        ..addAll(await _storage.loadDeviceConfigs());
      _log(DebugLogType.info, 'Config loaded: ${config.host}:${config.port}');
    } catch (error) {
      _log(DebugLogType.error, 'Failed to load config: $error');
    } finally {
      isConfigLoaded = true;
      notifyListeners();
    }
  }

  DeviceDisplayConfig deviceConfigFor(String identityKey) {
    return _deviceConfigs[identityKey] ?? const DeviceDisplayConfig();
  }

  String roomLabelFor(MasterState state) {
    return deviceConfigFor(state.identityKey).nameFor(state.deviceName);
  }

  Future<void> updateDeviceConfig(
    String identityKey,
    DeviceDisplayConfig nextConfig,
  ) async {
    _deviceConfigs[identityKey] = nextConfig;
    _log(DebugLogType.info, 'Device display config updated: $identityKey');
    try {
      await _storage.saveDeviceConfigs(_deviceConfigs);
      _log(DebugLogType.info, 'Device display config saved');
    } catch (error) {
      _log(DebugLogType.error, 'Failed to save device config: $error');
    }
    notifyListeners();
  }

  Future<void> updateConfig(MqttConnectionConfig nextConfig) async {
    config = nextConfig;
    _log(DebugLogType.info, 'Config updated: ${config.host}:${config.port}');
    try {
      await _storage.saveMqttConfig(config);
      _log(DebugLogType.info, 'Config saved');
    } catch (error) {
      _log(DebugLogType.error, 'Failed to save config: $error');
    }
    notifyListeners();
  }

  Future<void> connect() async {
    isConnecting = true;
    notifyListeners();
    try {
      await _mqttGateway.connect(
        config: config,
        onMessage: ingestStatePayload,
        onDisconnected: () {
          isConnected = false;
          _log(DebugLogType.info, 'MQTT disconnected');
          notifyListeners();
        },
      );
      isConnected = true;
      _log(DebugLogType.info, 'Subscribed ${config.stateTopic}');
    } catch (error) {
      isConnected = false;
      _log(DebugLogType.error, error.toString());
    } finally {
      isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _mqttGateway.disconnect();
    isConnected = false;
    _log(DebugLogType.info, 'MQTT disconnected by user');
    notifyListeners();
  }

  void ingestStatePayload(String topic, String payload) {
    lastRawState = payload;
    _log(DebugLogType.rx, '$topic\n$payload');
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('State payload must be a JSON object');
      }
      final state = MasterState.fromJson(decoded, DateTime.now());
      _registry[state.identityKey] = MasterRegistryItem(
        state: state,
        lastSeen: state.receivedAt,
        staleAfter: config.staleAfter,
      );
      activeMasterKey ??= state.identityKey;
    } catch (error) {
      _log(DebugLogType.error, 'Malformed state JSON: $error');
    }
    notifyListeners();
  }

  void selectMaster(String identityKey) {
    activeMasterKey = identityKey;
    _log(DebugLogType.info, 'Selected master $identityKey');
    notifyListeners();
  }

  void changeTab(int index) {
    currentTab = index;
    notifyListeners();
  }

  void sendLampCommand(int channelId, bool power) {
    if (!_ensureControlPublishAllowed()) return;
    final master = activeMaster;
    if (master == null) return;
    _publishCommand(
      MasterCommand.lamp(
        target: _commandTarget(master),
        channelId: channelId,
        power: power,
      ),
    );
  }

  void sendAllLampCommand(bool power) {
    if (!_ensureControlPublishAllowed()) return;
    final master = activeMaster;
    if (master == null) return;
    _publishCommand(
      MasterCommand.allLamps(target: _commandTarget(master), power: power),
    );
  }

  void sendAcCommand(bool power, double? targetTemperatureC) {
    if (!_ensureControlPublishAllowed()) return;
    final master = activeMaster;
    if (master == null) return;
    _publishCommand(
      MasterCommand.ac(
        target: _commandTarget(master),
        power: power,
        targetTemperatureC: targetTemperatureC,
      ),
    );
  }

  void sendProjectorCommand(bool power) {
    if (!_ensureControlPublishAllowed()) return;
    final master = activeMaster;
    if (master == null) return;
    _publishCommand(
      MasterCommand.projector(target: _commandTarget(master), power: power),
    );
  }

  void publishManualCommand(String payload) {
    final master = activeMaster;
    if (master == null) return;
    try {
      if (!MqttGateway.isValidJsonObject(payload)) {
        throw const FormatException('Command must be a JSON object');
      }
      _publishPayload(_commandTopic(master), payload);
    } catch (error) {
      _log(DebugLogType.error, 'Manual command rejected: $error');
      notifyListeners();
    }
  }

  void injectSampleState() {
    ingestStatePayload(
      config.stateTopic.replaceFirst('+', 'demo-master'),
      _sampleState,
    );
  }

  bool _ensureControlPublishAllowed() {
    if (canPublishControls) return true;
    final reason = !isConnected
        ? 'MQTT is offline'
        : activeMasterIsStale
        ? 'selected master is stale'
        : 'no active master selected';
    _log(DebugLogType.error, 'Control command blocked: $reason');
    notifyListeners();
    return false;
  }

  String _commandTarget(MasterState master) {
    return master.deviceId ?? master.deviceName;
  }

  String _commandTopic(MasterState master) {
    return config.commandTopicFor(master.identityKey);
  }

  void _publishCommand(MasterCommand command) {
    final master = activeMaster;
    if (master == null) return;
    _publishPayload(_commandTopic(master), command.encode());
  }

  void _publishPayload(String topic, String payload) {
    lastSentCommand = payload;
    _log(DebugLogType.tx, '$topic\n$payload');
    try {
      if (isConnected) {
        _mqttGateway.publishJson(topic: topic, payload: payload);
      } else {
        _log(DebugLogType.info, 'Command preview only because MQTT is offline');
      }
    } catch (error) {
      _log(DebugLogType.error, error.toString());
    }
    notifyListeners();
  }

  void _log(DebugLogType type, String message) {
    _debugLog.insert(
      0,
      DebugLogEntry(type: type, message: message, timestamp: DateTime.now()),
    );
    if (_debugLog.length > 100) {
      _debugLog.removeRange(100, _debugLog.length);
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    _mqttGateway.disconnect();
    super.dispose();
  }
}

const String _sampleState = '''
{
  "device_id": "master-demo-01",
  "device_name": "Lobby Master",
  "master_mac": "D4:8A:FC:10:22:01",
  "firmware_version": "1.0.0",
  "network": {
    "wifi_online": true,
    "lan_online": false,
    "mqtt_online": true,
    "rs485_online": true
  },
  "slaves": [
    {"address": 1, "uid": "SLV-001", "mac": "A0:01", "name": "Lobby Sensor", "capability": "sensor", "enabled": true, "relay_count": 0, "online": true},
    {"address": 2, "uid": "SLV-002", "mac": "A0:02", "name": "Lamp Relay", "capability": "relay", "enabled": true, "relay_count": 4, "online": true}
  ],
  "data": {
    "temperature": {"avg_c": 24.6, "points_c": [24.1, 24.3, 24.4, 24.6, 24.5, 24.7]},
    "co2_ppm": 612,
    "lux": 420,
    "human_presence": true
  },
  "controls": {
    "ac": {"available": true, "power": true, "target_temperature_c": 23},
    "projector": {"available": true, "power": false},
    "lights": {
      "available": true,
      "channels": [
        {"id": 1, "name": "Front", "power": true},
        {"id": 2, "name": "Middle", "power": false},
        {"id": 3, "name": "Back", "power": true},
        {"id": 4, "name": "Accent", "power": false}
      ]
    }
  }
}
''';
