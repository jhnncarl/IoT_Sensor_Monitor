class SensorReading {
  const SensorReading({
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  final double temperature;
  final double humidity;
  final DateTime timestamp;

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      temperature: _parseDouble(json['temperature']),
      humidity: _parseDouble(json['humidity']),
      timestamp: _parseTimestamp(json['timestamp']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }

    throw const FormatException('Sensor value is not a valid number.');
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is String) {
      return DateTime.parse(value).toLocal();
    }

    throw const FormatException('Timestamp is missing or invalid.');
  }
}
