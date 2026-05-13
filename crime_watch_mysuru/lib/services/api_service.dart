import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// For emulator use: http://10.0.2.2:5000
// For real device use your PC's local IP e.g: http://192.168.1.x:5000
const String baseUrl = 'http://10.0.2.2:5000';

const _timeout = Duration(seconds: 30);

class ApiService {
  static Future<http.Response> _get(String path) async {
    try {
      return await http.get(Uri.parse('$baseUrl$path')).timeout(_timeout);
    } on SocketException catch (e) {
      throw Exception('Cannot reach server: ${e.message}');
    }
  }

  static Future<http.Response> _post(String path, [Map<String, dynamic>? body]) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
    } on SocketException catch (e) {
      throw Exception('Cannot reach server: ${e.message}');
    }
  }

  static Future<void> trainModel() async {
    final res = await _post('/train');
    if (res.statusCode != 202 && res.statusCode != 200) {
      throw Exception('Training failed');
    }
    for (int i = 0; i < 60; i++) {
      await Future.delayed(const Duration(seconds: 3));
      final status = await getStatus();
      if (status['training_in_progress'] == false) return;
    }
    throw Exception('Training timed out');
  }

  static Future<Map<String, dynamic>> getAnalytics() async {
    final res = await _get('/api/analytics');
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load analytics');
  }

  static Future<Map<String, dynamic>> getStatus() async {
    final res = await _get('/api/status');
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load status');
  }

  static Future<Map<String, dynamic>> predict({
    required String area,
    required int hour,
    required String day,
    required String month,
    required String weather,
    required int populationDensity,
    required int isWeekend,
    required int isFestival,
  }) async {
    final res = await _post('/api/predict', {
      'area': area,
      'hour': hour,
      'day': day,
      'month': month,
      'weather': weather,
      'population_density': populationDensity,
      'is_weekend': isWeekend,
      'is_festival': isFestival,
    });
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['error'] ?? 'Prediction failed');
  }

  static Future<void> sendAlert({
    required String area,
    required String message,
    required String severity,
  }) async {
    final res = await _post('/api/alert', {
      'area': area,
      'message': message,
      'severity': severity,
    });
    if (res.statusCode != 200) throw Exception('Alert failed: ${res.body}');
  }
}
