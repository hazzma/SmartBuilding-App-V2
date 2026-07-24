import 'network_state.dart';
import 'sensor_data.dart';
import 'slave_info.dart';
import 'control_state.dart';

// EDIT_TARGET: master_state.dart
// EDIT_PURPOSE: Memetakan payload state master menjadi model aplikasi.
// EDIT_REASON: App harus mengabaikan field unknown dan tetap tahan payload parsial.
class MasterState {
  const MasterState({
    required this.identityKey,
    required this.deviceId,
    required this.deviceName,
    required this.masterMac,
    required this.firmwareVersion,
    required this.network,
    required this.slaves,
    required this.sensorData,
    required this.controls,
    required this.rawJson,
    required this.receivedAt,
  });

  factory MasterState.fromJson(Map<String, dynamic> json, DateTime receivedAt) {
    final deviceId = json['device_id']?.toString();
    final deviceName = json['device_name']?.toString() ?? 'Smart Master';
    final masterMac = json['master_mac']?.toString();
    final identityKey = _identityKey(deviceId, deviceName, masterMac);
    final slaves = json['slaves'] is List
        ? (json['slaves'] as List)
              .whereType<Map<String, dynamic>>()
              .map(SlaveInfo.fromJson)
              .toList(growable: false)
        : <SlaveInfo>[];

    return MasterState(
      identityKey: identityKey,
      deviceId: deviceId,
      deviceName: deviceName,
      masterMac: masterMac,
      firmwareVersion: json['firmware_version']?.toString() ?? '-',
      network: NetworkState.fromJson(_map(json['network'])),
      slaves: slaves,
      sensorData: SensorData.fromJson(
        _map(json['data']) ?? _map(json['sensor']),
      ),
      controls: ControlState.fromJson(_map(json['controls'])),
      rawJson: json,
      receivedAt: receivedAt,
    );
  }

  final String identityKey;
  final String? deviceId;
  final String deviceName;
  final String? masterMac;
  final String firmwareVersion;
  final NetworkState network;
  final List<SlaveInfo> slaves;
  final SensorData sensorData;
  final ControlState controls;
  final Map<String, dynamic> rawJson;
  final DateTime receivedAt;

  int get onlineSlaveCount =>
      slaves.where((slave) => slave.online == true).length;

  int get offlineSlaveCount =>
      slaves.where((slave) => slave.online == false).length;

  static String _identityKey(String? deviceId, String deviceName, String? mac) {
    if (deviceId != null && deviceId.isNotEmpty) return deviceId;
    if (mac != null && mac.isNotEmpty) return '$deviceName-$mac';
    return deviceName;
  }

  static Map<String, dynamic>? _map(Object? value) {
    return value is Map<String, dynamic> ? value : null;
  }
}
