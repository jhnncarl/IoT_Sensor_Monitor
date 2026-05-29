import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_reading.dart';

class SupabaseService {
  SupabaseService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Set this to false when you are ready to connect to the real Supabase API.
  static const bool useDemoData = false;

  // Replace these placeholders with your real Supabase project values later.
  static const String supabaseUrl = 'https://xfumytkobyygaongyaax.supabase.co';
  static const String supabaseApiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmdW15dGtvYnl5Z2Fvbmd5YWF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNDM4MzEsImV4cCI6MjA5NTYxOTgzMX0.Vumdgb2L7GiUbTG7RRKP2ua0ngyBukpfllnLe1gy3lU';
  static const String tableName = 'sensor_readings';

  Future<SensorReading> fetchLatestReading() async {
    if (useDemoData) {
      return _fetchDemoReading();
    }

    final uri = Uri.parse(
      '$supabaseUrl/rest/v1/$tableName',
    ).replace(
      queryParameters: const {
        'select': 'temperature,humidity,timestamp',
        'order': 'timestamp.desc',
        'limit': '1',
      },
    );

    final response = await _client.get(
      uri,
      headers: const {
        'apikey': supabaseApiKey,
        'Authorization': 'Bearer $supabaseApiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Supabase request failed with status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      throw Exception('No sensor readings were returned from Supabase.');
    }

    final latest = decoded.first;
    if (latest is! Map<String, dynamic>) {
      throw const FormatException('Unexpected sensor reading JSON format.');
    }

    return SensorReading.fromJson(latest);
  }

  Future<SensorReading> _fetchDemoReading() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    return SensorReading(
      temperature: 28.4,
      humidity: 64.2,
      timestamp: DateTime.now(),
    );
  }

  void dispose() {
    _client.close();
  }
}
