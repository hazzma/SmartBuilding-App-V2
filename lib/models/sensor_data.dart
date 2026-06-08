// EDIT_TARGET: sensor_data.dart
// EDIT_PURPOSE: Represents latest classroom sensor values and trend points.
// EDIT_REASON: FSD V2 needs nullable sensor readings so unavailable data is explicit.

class SensorData {
  const SensorData({
    this.temperatureAvg,
    this.temperaturePoints = const <double>[],
    this.lux,
    this.humanPresence,
    this.isStale = false,
  });

  final double? temperatureAvg;
  final List<double> temperaturePoints;
  final int? lux;
  final bool? humanPresence;
  final bool isStale;

  Map<String, dynamic> toJson() {
    return {
      'temperatureAvg': temperatureAvg,
      'temperaturePoints': temperaturePoints,
      'lux': lux,
      'humanPresence': humanPresence,
      'isStale': isStale,
    };
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperatureAvg: (json['temperatureAvg'] as num?)?.toDouble(),
      temperaturePoints:
          (json['temperaturePoints'] as List<dynamic>? ?? const [])
              .map((item) => (item as num).toDouble())
              .toList(),
      lux: json['lux'] as int?,
      humanPresence: json['humanPresence'] as bool?,
      isStale: json['isStale'] as bool? ?? false,
    );
  }
}
