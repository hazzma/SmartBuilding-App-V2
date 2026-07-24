import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/mqtt_connection_config.dart';

// EDIT_TARGET: mqtt_gateway.dart
// EDIT_PURPOSE: Menyediakan adapter MQTT connect, subscribe, publish, disconnect.
// EDIT_REASON: App harus terhubung ke broker MQTT dan publish command ke master aktif.
class MqttGateway {
  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _subscription;

  Future<void> connect({
    required MqttConnectionConfig config,
    required void Function(String topic, String payload) onMessage,
    required void Function() onDisconnected,
  }) async {
    await disconnect();

    final clientId = 'smartbuild-v2-${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient.withPort(config.host, clientId, config.port)
      ..logging(on: false)
      ..keepAlivePeriod = 20
      ..onDisconnected = onDisconnected
      ..connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

    _client = client;
    await client.connect(
      config.username.isEmpty ? null : config.username,
      config.password.isEmpty ? null : config.password,
    );

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      final status = client.connectionStatus?.returnCode ?? 'unknown';
      client.disconnect();
      throw StateError('MQTT connect failed: $status');
    }

    client.subscribe(config.stateTopic, MqttQos.atLeastOnce);
    _subscription = client.updates?.listen((messages) {
      for (final message in messages) {
        final publishMessage = message.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          publishMessage.payload.message,
        );
        onMessage(message.topic, payload);
      }
    });
  }

  void publishJson({required String topic, required String payload}) {
    final client = _client;
    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      throw StateError('MQTT is not connected');
    }
    final builder = MqttClientPayloadBuilder()..addString(payload);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _client?.disconnect();
    _client = null;
  }

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  static bool isValidJsonObject(String payload) {
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic>;
  }
}
