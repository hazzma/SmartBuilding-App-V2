// EDIT_TARGET: slave_info.dart
// EDIT_PURPOSE: Menyimpan data slave generic dari payload master.
// EDIT_REASON: FSD menyatakan slave bersifat generic dan ditampilkan di detail.
class SlaveInfo {
  const SlaveInfo({
    required this.address,
    required this.uid,
    required this.mac,
    required this.name,
    required this.capability,
    required this.enabled,
    required this.relayCount,
    required this.online,
  });

  factory SlaveInfo.fromJson(Map<String, dynamic> json) {
    return SlaveInfo(
      address: _readInt(json['address']) ?? _readInt(json['addr']) ?? 0,
      uid: json['uid']?.toString() ?? '',
      mac: json['mac']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Slave',
      capability: json['capability']?.toString() ?? 'generic',
      enabled: _readBool(json['enabled']) ?? true,
      relayCount:
          _readInt(json['relay_count']) ?? _readInt(json['relays']) ?? 0,
      online: _readBool(json['online']),
    );
  }

  final int address;
  final String uid;
  final String mac;
  final String name;
  final String capability;
  final bool enabled;
  final int relayCount;
  final bool? online;

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return null;
  }
}
