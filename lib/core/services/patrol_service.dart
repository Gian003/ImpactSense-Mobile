import 'api_client.dart';
import 'session_service.dart';

class PatrolService {
  static Future<bool> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) return false;

      final res = await ApiClient.post(
        'patrol/update-location',
        {'latitude': latitude, 'longitude': longitude},
        token: token,
      );

      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
