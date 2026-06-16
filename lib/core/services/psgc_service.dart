import 'dart:convert';
import 'package:http/http.dart' as http;

class PsgcLocation {
  final String code;
  final String name;

  const PsgcLocation({required this.code, required this.name});

  factory PsgcLocation.fromJson(Map<String, dynamic> json) =>
      PsgcLocation(code: json['code'] as String, name: json['name'] as String);
}

class PsgcService {
  static const _base = 'https://psgc.gitlab.io/api';

  static Future<List<PsgcLocation>> fetchProvinces() =>
      _get('$_base/provinces/');

  static Future<List<PsgcLocation>> fetchMunicipalities(
          String provinceCode) =>
      _get('$_base/provinces/$provinceCode/cities-municipalities/');

  static Future<List<PsgcLocation>> fetchBarangays(
          String cityMunCode) =>
      _get('$_base/cities-municipalities/$cityMunCode/barangays/');

  static Future<List<PsgcLocation>> _get(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('PSGC request failed: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    final locations = data
        .map((e) => PsgcLocation.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return locations;
  }
}
