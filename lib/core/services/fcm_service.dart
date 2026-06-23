import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:impactsense/core/services/api_client.dart';
import 'package:impactsense/core/services/session_service.dart';

// Top-level handler required by Firebase for background messages.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) print('[FCM] background message: ${message.notification?.title}');
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  /// Call once from main() after Firebase.initializeApp().
  static Future<void> init() async {
    // Request permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Upload token to backend whenever it refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen(_syncToken);

    // Upload current token on first launch
    try {
      final token = await _messaging.getToken();
      if (token != null) await _syncToken(token);
    } catch (e) {
      if (kDebugMode) print('[FCM] getToken failed (Play Services unavailable?): $e');
    }
  }

  /// Handle a foreground message (called from the app's UI layer).
  static void listenForeground(void Function(RemoteMessage) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  /// Handle tap on a notification when the app is in the background / terminated.
  static void listenOnOpen(void Function(RemoteMessage) handler) {
    // App opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) handler(msg);
    });
    // App resumed from background
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  static Future<void> _syncToken(String token) async {
    final sessionToken = await SessionService.getToken();
    final role = await SessionService.getRole();
    if (sessionToken == null) return;

    final endpoint = role == 'patrol' ? 'patrol/fcm-token' : 'rider/fcm-token';
    try {
      await ApiClient.post(endpoint, {'fcm_token': token}, token: sessionToken);
    } catch (_) {
      // Non-fatal — token will sync on next launch.
    }
  }
}
