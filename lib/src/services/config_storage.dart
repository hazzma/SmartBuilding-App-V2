import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_display_config.dart';
import '../models/mqtt_connection_config.dart';

// EDIT_TARGET: config_storage.dart
// EDIT_PURPOSE: Menyimpan dan membaca konfigurasi MQTT dari local preferences.
// EDIT_REASON: Broker host, topic custom, dan interval publish tidak boleh hilang saat app restart.
class ConfigStorage {
  static const _mqttConfigKey = 'smartbuild.mqtt_config';
  static const _deviceConfigsKey = 'smartbuild.device_display_configs';

  Future<MqttConnectionConfig?> loadMqttConfig() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_mqttConfigKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return MqttConnectionConfig.fromStorageJson(decoded);
  }

  Future<void> saveMqttConfig(MqttConnectionConfig config) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _mqttConfigKey,
      jsonEncode(config.toStorageJson()),
    );
  }

  // EDIT_TARGET: config_storage.dart
  // EDIT_PURPOSE: Membaca konfigurasi tampilan per master dari local preferences.
  // EDIT_REASON: Devices harus bisa menyimpan showInHome, nama room, sensor/control, dan debug.
  Future<Map<String, DeviceDisplayConfig>> loadDeviceConfigs() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_deviceConfigsKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return {};
    return {
      for (final entry in decoded.entries)
        if (entry.value is Map<String, dynamic>)
          entry.key: DeviceDisplayConfig.fromStorageJson(
            entry.value as Map<String, dynamic>,
          ),
    };
  }

  // EDIT_TARGET: config_storage.dart
  // EDIT_PURPOSE: Menyimpan konfigurasi tampilan per master ke local preferences.
  // EDIT_REASON: Pilihan Devices harus bertahan saat app dibuka ulang.
  Future<void> saveDeviceConfigs(
    Map<String, DeviceDisplayConfig> configs,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _deviceConfigsKey,
      jsonEncode({
        for (final entry in configs.entries)
          entry.key: entry.value.toStorageJson(),
      }),
    );
  }
}
