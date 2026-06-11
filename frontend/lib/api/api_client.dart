import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/plant.dart';

/// REST client for the FastAPI backend.
///
/// Override the base URL per platform at build/run time:
///   flutter run --dart-define=API_BASE=http://10.0.2.2:8000   (Android emulator)
///   flutter run --dart-define=API_BASE=http://192.168.1.50:8000 (physical phone, LAN)
class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8000',
  );

  final http.Client _client = http.Client();

  Future<List<PlantSummary>> fetchPlants() async {
    final json = await _getJson('/api/v1/plants') as List;
    return json
        .map((p) => PlantSummary.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<PlantSummary> fetchCurrent(String plantId) async {
    final json = await _getJson('/api/v1/plants/$plantId/current');
    return PlantSummary.fromJson(json as Map<String, dynamic>);
  }

  Future<PlantHistory> fetchHistory(String plantId, {int hours = 24}) async {
    final json = await _getJson('/api/v1/plants/$plantId/history?hours=$hours');
    return PlantHistory.fromJson(json as Map<String, dynamic>);
  }

  Future<dynamic> _getJson(String path) async {
    final response = await _client
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'API error $statusCode: $body';
}
