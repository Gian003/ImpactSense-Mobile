import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // Android emulator → 10.0.2.2 maps to host machine localhost.
  // Physical device → replace with your machine's LAN IP (e.g. 192.168.1.x).
  // iOS simulator → use 127.0.0.1.
  static const String baseUrl = 'http://10.0.2.2/api';

  static const Duration _timeout = Duration(seconds: 15);

  static Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/$endpoint'),
          headers: _headers(token: token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/$endpoint'),
          headers: _headers(token: token),
        )
        .timeout(_timeout);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
