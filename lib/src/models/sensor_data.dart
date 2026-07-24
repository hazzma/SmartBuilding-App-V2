// EDIT_TARGET: sensor_data.dart
// EDIT_PURPOSE: Memetakan sensor temperature, CO2, lux, dan human presence.
// EDIT_REASON: Dashboard harus menampilkan sensor valid dan mengabaikan placeholder.
class SensorData {
  const SensorData({
    required this.temperatureAverageC,
    required this.temperaturePointsC,
    required this.co2Ppm,
    required this.lux,
    required this.humanPresence,
  });

  factory SensorData.fromJson(Map<String, dynamic>? json) {
    final temperature = json?['temperature'];
    final temperatureMap = temperature is Map<String, dynamic>
        ? temperature
        : <String, dynamic>{};

    return SensorData(
      temperatureAverageC: _validNumber(
        temperatureMap['avg_c'] ?? json?['temperature_avg_c'],
      ),
      temperaturePointsC: _readPoints(
        temperatureMap['points_c'] ?? temperatureMap['points'],
      ),
      co2Ppm: _validNumber(json?['co2_ppm']),
      lux: _validNumber(json?['lux']),
      humanPresence: _readBool(json?['human_presence']),
    );
  }

  final double? temperatureAverageC;
  final List<double> temperaturePointsC;
  final double? co2Ppm;
  final double? lux;
  final bool? humanPresence;

  static double? _validNumber(Object? value) {
    final number = switch (value) {
      int v => v.toDouble(),
      double v => v,
      String v => double.tryParse(v),
      _ => null,
    };
    if (number == null || number == -100) return null;
    return number;
  }

  static List<double> _readPoints(Object? value) {
    if (value is! List) return const [];
    return value.map(_validNumber).whereType<double>().toList(growable: false);
  }

  static bool? _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return null;
  }
}
