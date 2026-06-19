import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingResult {
  final String displayName;
  final LatLng position;

  const GeocodingResult({required this.displayName, required this.position});
}

class RoutingService {
  static const _userAgent = 'ImpactSense/1.0 (impactsense-app)';

  /// Search for places in the Philippines using Nominatim.
  static Future<List<GeocodingResult>> searchPlaces(String query) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&limit=5'
      '&countrycodes=ph',
    );
    try {
      final res = await http.get(uri, headers: {'User-Agent': _userAgent});
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((item) {
        final m = item as Map<String, dynamic>;
        return GeocodingResult(
          displayName: m['display_name'] as String,
          position: LatLng(
            double.parse(m['lat'] as String),
            double.parse(m['lon'] as String),
          ),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch a driving route between [start] and [end] using OSRM.
  /// Returns an ordered list of LatLng points for the polyline.
  static Future<List<LatLng>> fetchRoute(LatLng start, LatLng end) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};'
      '${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );
    try {
      final res = await http.get(uri, headers: {'User-Agent': _userAgent});
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) return [];
      final coords = (routes[0] as Map<String, dynamic>)['geometry']
          ['coordinates'] as List<dynamic>;
      // GeoJSON is [lng, lat] — swap to LatLng(lat, lng)
      return coords.map((c) {
        final pair = c as List<dynamic>;
        return LatLng(pair[1] as double, pair[0] as double);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
