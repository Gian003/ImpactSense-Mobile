import 'api_client.dart';
import 'session_service.dart';

class AuthResult {
  final bool success;
  final String message;

  const AuthResult({required this.success, required this.message});
}

class AuthService {
  static Future<AuthResult> registerRider({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phoneNumber,
  }) async {
    try {
      final res = await ApiClient.post('rider/register', {
        'full_name': fullName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      });

      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;
        await SessionService.save(
          token: data['token'] as String,
          role: 'rider',
          name: user['full_name'] as String?,
          email: user['email'] as String?,
        );
        return AuthResult(success: true, message: res['message'] as String);
      }

      return AuthResult(
        success: false,
        message: _extractError(res),
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Connection error. Check your network.');
    }
  }

  static Future<AuthResult> loginRider({
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiClient.post('rider/login', {
        'email': email,
        'password': password,
      });

      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;
        await SessionService.save(
          token: data['token'] as String,
          role: 'rider',
          name: user['full_name'] as String?,
          email: user['email'] as String?,
        );
        return AuthResult(success: true, message: res['message'] as String);
      }

      return AuthResult(success: false, message: _extractError(res));
    } catch (e) {
      return AuthResult(success: false, message: 'Connection error. Check your network.');
    }
  }

  static Future<AuthResult> loginPatrol({
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiClient.post('patrol/login', {
        'email': email,
        'password': password,
      });

      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        final unit = data['patrol_unit'] as Map<String, dynamic>;
        await SessionService.save(
          token: data['token'] as String,
          role: 'patrol',
          name: unit['full_name'] as String?,
          email: unit['email'] as String?,
        );
        return AuthResult(success: true, message: res['message'] as String);
      }

      return AuthResult(success: false, message: _extractError(res));
    } catch (e) {
      return AuthResult(success: false, message: 'Connection error. Check your network.');
    }
  }

  static Future<void> logout() async {
    try {
      final token = await SessionService.getToken();
      final role = await SessionService.getRole();
      if (token != null) {
        final endpoint = role == 'patrol' ? 'patrol/logout' : 'rider/logout';
        await ApiClient.post(endpoint, {}, token: token);
      }
    } catch (_) {
      // Always clear locally even if the server call fails.
    } finally {
      await SessionService.clear();
    }
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
