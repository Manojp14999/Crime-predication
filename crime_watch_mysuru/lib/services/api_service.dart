import 'dart:convert';
import 'package:http/http.dart' as http;

// For emulator use: http://10.0.2.2:5000
// For real device use your PC's local IP e.g: http://192.168.1.x:5000
const String baseUrl = 'http://10.0.2.2:5000';

class ApiService {
  static Future<void> trainModel() async {
    final res = await http.post(Uri.parse('$baseUrl/train'),
        headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) throw Exception('Training failed');
  }

  static Future<Map<String, dynamic>> getAnalytics() async {
    final res = await http.get(Uri.parse('$baseUrl/api/analytics'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load analytics');
  }

  static Future<Map<String, dynamic>> getStatus() async {
    final res = await http.get(Uri.parse('$baseUrl/api/status'));
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
    final res = await http.post(
      Uri.parse('$baseUrl/api/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'area': area,
        'hour': hour,
        'day': day,
        'month': month,
        'weather': weather,
        'population_density': populationDensity,
        'is_weekend': isWeekend,
        'is_festival': isFestival,
      }),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['error'] ?? 'Prediction failed');
  }

  static Future<List<Map<String, dynamic>>> getHotspots() async {
    final data = await getAnalytics();
    final hotspots = data['hotspots'] as List? ?? [];
    return hotspots.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> sendAlert({
    required String area,
    required String message,
    required String severity,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/alert'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'area': area, 'message': message, 'severity': severity}),
    );
    if (res.statusCode != 200) throw Exception('Alert failed: ${res.body}');
  }
}
