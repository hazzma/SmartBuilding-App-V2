// EDIT_TARGET: mqtt_connection_config.dart
// EDIT_PURPOSE: Menyimpan konfigurasi broker dan template topic MQTT aplikasi.
// EDIT_REASON: FSD mewajibkan Broker Setup mendukung topic default dan custom.
class MqttConnectionConfig {
  const MqttConnectionConfig({
    this.host = 'localhost',
    this.port = 1883,
    this.username = '',
    this.password = '',
    this.stateTopic = 'smart-building/master/+/state',
    this.commandTopicTemplate = 'smart-building/master/{master}/command',
    this.publishIntervalSeconds = 10,
  });

  final String host;
  final int port;
  final String username;
  final String password;
  final String stateTopic;
  final String commandTopicTemplate;
  final int publishIntervalSeconds;

  String commandTopicFor(String masterKey) {
    return commandTopicTemplate.replaceAll('{master}', masterKey);
  }

  Duration get staleAfter => Duration(seconds: publishIntervalSeconds * 3);

  // EDIT_TARGET: mqtt_connection_config.dart
  // EDIT_PURPOSE: Mengubah config menjadi Map untuk penyimpanan lokal.
  // EDIT_REASON: Broker/topic custom perlu tetap tersimpan setelah app ditutup.
  Map<String, Object> toStorageJson() {
    return {
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'stateTopic': stateTopic,
      'commandTopicTemplate': commandTopicTemplate,
      'publishIntervalSeconds': publishIntervalSeconds,
    };
  }

  // EDIT_TARGET: mqtt_connection_config.dart
  // EDIT_PURPOSE: Membaca config dari Map penyimpanan lokal.
  // EDIT_REASON: App harus bisa memulihkan topic/broker custom saat dibuka lagi.
  factory MqttConnectionConfig.fromStorageJson(Map<String, dynamic> json) {
    return MqttConnectionConfig(
      host: json['host']?.toString() ?? 'localhost',
      port: _readInt(json['port']) ?? 1883,
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      stateTopic:
          json['stateTopic']?.toString() ?? 'smart-building/master/+/state',
      commandTopicTemplate:
          json['commandTopicTemplate']?.toString() ??
          'smart-building/master/{master}/command',
      publishIntervalSeconds: _readInt(json['publishIntervalSeconds']) ?? 10,
    );
  }

  MqttConnectionConfig copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    String? stateTopic,
    String? commandTopicTemplate,
    int? publishIntervalSeconds,
  }) {
    return MqttConnectionConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      stateTopic: stateTopic ?? this.stateTopic,
      commandTopicTemplate: commandTopicTemplate ?? this.commandTopicTemplate,
      publishIntervalSeconds:
          publishIntervalSeconds ?? this.publishIntervalSeconds,
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
