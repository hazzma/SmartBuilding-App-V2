// EDIT_TARGET: network_state.dart
// EDIT_PURPOSE: Memetakan status koneksi WiFi, LAN, MQTT, dan RS485 dari master.
// EDIT_REASON: Master card dan detail wajib menampilkan status network/RS485.
class NetworkState {
  const NetworkState({
    required this.wifiOnline,
    required this.lanOnline,
    required this.mqttOnline,
    required this.rs485Online,
  });

  factory NetworkState.fromJson(Map<String, dynamic>? json) {
    return NetworkState(
      wifiOnline: _readBool(json, ['wifi_online', 'wifi', 'wifi_connected']),
      lanOnline: _readBool(json, ['lan_online', 'lan', 'lan_connected']),
      mqttOnline: _readBool(json, ['mqtt_online', 'mqtt', 'mqtt_connected']),
      rs485Online: _readBool(json, [
        'rs485_online',
        'rs485',
        'rs485_connected',
      ]),
    );
  }

  final bool? wifiOnline;
  final bool? lanOnline;
  final bool? mqttOnline;
  final bool? rs485Online;

  static bool? _readBool(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return null;
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase();
        if (normalized == 'online' ||
            normalized == 'connected' ||
            normalized == 'true') {
          return true;
        }
        if (normalized == 'offline' ||
            normalized == 'disconnected' ||
            normalized == 'false') {
          return false;
        }
      }
    }
    return null;
  }
}
