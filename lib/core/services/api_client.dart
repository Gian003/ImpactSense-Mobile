import 'dart:convert';
import 'package:http/http.dart' as http;
import 'host_resolver.dart';

class ApiClient {
  // ════════════════════════════════════════════════════════════════════════════
  // BASE URL — set _mode below to match your current testing target.
  //
  //  HOW TO START THE SERVER (run in ImpactSenseAdmin folder):
  //    composer run dev
  //    (this now binds 0.0.0.0:8000 and advertises "impactsense.local" via
  //    mDNS — see ImpactSenceAdmin's scripts/mdns-advertise.js)
  //
  //  ┌─────────────────────────────────────────────────────────────────────┐
  //  │ 1. Android Emulator                                                 │
  //  │    10.0.2.2 is the emulator's alias for the host machine localhost  │
  //  │                                                                     │
  //  │ 2. iOS Simulator                                                    │
  //  │    The simulator shares the host machine's localhost directly       │
  //  │                                                                     │
  //  │ 3. Physical Device on LAN (Wi-Fi) — mDNS hostname (recommended)     │
  //  │    • Phone and PC must be on the SAME Wi-Fi network                 │
  //  │    • Resolved at runtime via HostResolver (host_resolver.dart), so  │
  //  │      it survives the PC's IP changing (DHCP) — no edit needed here  │
  //  │    • Open Windows Firewall and allow port 8000 if blocked           │
  //  │    • If mDNS is blocked on your network/router, set _mode to        │
  //  │      BaseUrlMode.rawIp and fill in _rawIpFallback below instead     │
  //  └─────────────────────────────────────────────────────────────────────┘
  // ════════════════════════════════════════════════════════════════════════════

  static const BaseUrlMode _mode = BaseUrlMode.physicalDeviceMdns;

  // Only used when _mode == BaseUrlMode.rawIp. Run `ipconfig` on the PC
  // running the backend and paste its Wi-Fi IPv4 address here.
  static const String _rawIpFallback = '192.168.1.5';

  static const Duration _timeout = Duration(seconds: 15);

  static Future<String> get baseUrl async {
    switch (_mode) {
      case BaseUrlMode.androidEmulator:
        return 'http://10.0.2.2:8000/api';
      case BaseUrlMode.iosSimulator:
        return 'http://127.0.0.1:8000/api';
      case BaseUrlMode.rawIp:
        return 'http://$_rawIpFallback:8000/api';
      case BaseUrlMode.physicalDeviceMdns:
        final host = await HostResolver.resolveApiHost();
        // Falls back to the literal ".local" name (works on iOS/macOS, whose
        // OS resolver handles mDNS natively) if our own mDNS query hasn't
        // resolved an IP yet - see host_resolver.dart for why Android needs
        // the explicit query instead of relying on that OS behavior.
        return 'http://${host ?? HostResolver.mdnsName}:8000/api';
    }
  }

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
    final base = await baseUrl;
    final response = await http
        .post(
          Uri.parse('$base/$endpoint'),
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
    final base = await baseUrl;
    final response = await http
        .get(Uri.parse('$base/$endpoint'), headers: _headers(token: token))
        .timeout(_timeout);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
  }) async {
    final base = await baseUrl;
    final response = await http
        .delete(
          Uri.parse('$base/$endpoint'),
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
    final base = await baseUrl;
    final response = await http
        .patch(
          Uri.parse('$base/$endpoint'),
          headers: _headers(token: token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

enum BaseUrlMode { androidEmulator, iosSimulator, physicalDeviceMdns, rawIp }
