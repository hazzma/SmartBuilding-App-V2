// EDIT_TARGET: debug_log_entry.dart
// EDIT_PURPOSE: Mendefinisikan item log TX/RX/error untuk DebugScreen.
// EDIT_REASON: FSD meminta debug mode menampilkan MQTT log dan malformed JSON.
class DebugLogEntry {
  const DebugLogEntry({
    required this.type,
    required this.message,
    required this.timestamp,
  });

  final DebugLogType type;
  final String message;
  final DateTime timestamp;
}

enum DebugLogType { rx, tx, error, info }
