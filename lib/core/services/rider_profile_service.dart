import 'api_client.dart';
import 'session_service.dart';

class ProfileResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? user;

  const ProfileResult({required this.success, required this.message, this.user});
}

class RiderProfileService {
  static Future<ProfileResult> fetchProfile() async {
    try {
      final token = await SessionService.getToken();
      if (token == null) {
        return const ProfileResult(success: false, message: 'Not logged in.');
      }

      final res = await ApiClient.get('rider/profile', token: token);
      if (res['success'] == true) {
        final user = res['data'] as Map<String, dynamic>;
        await _cacheUser(user);
        return ProfileResult(success: true, message: 'Profile retrieved', user: user);
      }

      return ProfileResult(
          success: false, message: res['message'] as String? ?? 'Failed to load profile.');
    } catch (e) {
      return const ProfileResult(
          success: false, message: 'Connection error. Check your network.');
    }
  }

  static Future<ProfileResult> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? dateOfBirth, // ISO format: YYYY-MM-DD
  }) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) {
        return const ProfileResult(success: false, message: 'Not logged in.');
      }

      final res = await ApiClient.patch('rider/profile', {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (address != null) 'address': address,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      }, token: token);

      if (res['success'] == true) {
        final user = res['data'] as Map<String, dynamic>;
        await _cacheUser(user);
        return ProfileResult(
            success: true, message: res['message'] as String, user: user);
      }

      return ProfileResult(success: false, message: _extractError(res));
    } catch (e) {
      return const ProfileResult(
          success: false, message: 'Connection error. Check your network.');
    }
  }

  static Future<void> _cacheUser(Map<String, dynamic> user) async {
    final token = await SessionService.getToken();
    if (token == null) return;
    await SessionService.save(
      token: token,
      role: 'rider',
      name: user['full_name'] as String?,
      email: user['email'] as String?,
      userId: (user['id'] as num?)?.toInt(),
    );
  }

  static String _extractError(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map) {
      final errors = data.values.first;
      if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      }
    }
    return res['message'] as String? ?? 'Something went wrong.';
  }
}
