import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // ════════════════════════════════════════════════════════════════════════════
  // BASE URL — uncomment the line that matches your current testing target,
  //            comment out the others.
  //
  //  HOW TO START THE SERVER (run in ImpactSenseAdmin folder):
  //    php artisan serve --host=0.0.0.0 --port=8000
  //
  //  ┌─────────────────────────────────────────────────────────────────────┐
  //  │ 1. Android Emulator                                                 │
  //  │    10.0.2.2 is the emulator's alias for the host machine localhost  │
  // static const String baseUrl = 'http://10.0.2.2:8000/api';             │
  //  │                                                                     │
  //  │ 2. iOS Simulator                                                    │
  //  │    The simulator shares the host machine's localhost directly       │
  // static const String baseUrl = 'http://127.0.0.1:8000/api';            │
  //  │                                                                     │
  //  │ 3. Physical Device on LAN (Wi-Fi)                                   │
  //  │    • Run `ipconfig` on your PC                                      │
  //  │    • Copy the Wi-Fi adapter's IPv4 Address (e.g. 192.168.1.5)      │
  //  │    • Phone and PC must be on the SAME Wi-Fi network                 │
  //  │    • Open Windows Firewall and allow port 8000 if blocked           │
  //  │    • Test by visiting http://YOUR_IP:8000/api/health in phone       │
  //  │      browser — should return {"status":"up"}                        │
  // static const String baseUrl = 'http://192.168.1.5:8000/api';          │
  //  └─────────────────────────────────────────────────────────────────────┘
  // ════════════════════════════════════════════════════════════════════════════

  // ▼ ACTIVE TARGET — change this line only ▼
  static const String baseUrl = 'http://192.168.1.5:8000/api';

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

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/$endpoint'),
          headers: _headers(token: token),
        )
        .timeout(_timeout);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/$endpoint'),
          headers: _headers(token: token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
