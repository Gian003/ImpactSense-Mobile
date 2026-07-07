import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:impactsense/core/services/fcm_service.dart';
import 'package:impactsense/screens/auth/authenticaion_verify.dart';
import 'package:impactsense/screens/auth/device_synced_screen.dart';
import 'package:impactsense/screens/auth/login_screen.dart';
import 'package:impactsense/screens/auth/otp_verify.dart';
import 'package:impactsense/screens/auth/personal_information_screen.dart';
import 'package:impactsense/screens/auth/registration_screen.dart';
import 'package:impactsense/screens/riders/emergency/accident_detected_screen.dart';
import 'package:impactsense/screens/riders/emergency/emergency_alert_sent_screen.dart';
import 'package:impactsense/screens/riders/home/home_screen.dart';
import 'package:impactsense/screens/riders/emergency/voice_assistant_screen.dart';
import 'package:impactsense/screens/patrols/auth/patrol_registration_screen.dart';
import 'package:impactsense/screens/patrols/home/patrol_accident_map_screen.dart';
import 'package:impactsense/screens/patrols/home/patrol_home_screen.dart';
import 'package:impactsense/screens/patrols/settings/patrol_terms_screen.dart';
import 'package:impactsense/screens/patrols/settings/patrol_privacy_screen.dart';
import 'package:impactsense/screens/onboarding/on_boarding_screen.dart';
import 'package:impactsense/screens/splash/splash_screen.dart';

/// Lets a top-level FCM handler navigate even though it runs outside the
/// widget tree (no BuildContext of its own).
final navigatorKey = GlobalKey<NavigatorState>();

// A device-reported crash (or rider-app-confirmed crash) pushes one of these
// types - open the Accident Detected screen automatically so the rider sees
// the cancellation window without having to open the app and find it manually.
void _handleFcmMessage(RemoteMessage message) {
  final type = message.data['type'];
  if (type == 'crash_detected' || type == 'crash_confirmed') {
    navigatorKey.currentState?.pushNamed('/accident', arguments: {'alreadyReported': true});
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FcmService.init();
  FcmService.listenForeground(_handleFcmMessage);
  FcmService.listenOnOpen(_handleFcmMessage);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      themeMode: ThemeMode.system,
      title: 'ImpactSense',
      debugShowCheckedModeBanner: false,
      home: SplashScreenWrapper(),
      routes: {
        '/onboarding': (_) => const OnBoardingScreen(),
        '/auth-verify': (_) => const AuthenticationVerifyScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegistrationScreen(),
        '/otp-verify': (_) => const OtpVerifyScreen(),
        '/personal-info': (_) => const PersonalInformationScreen(),
        '/device-synced': (_) => const DeviceSyncedScreen(),
        '/home': (_) => const HomeScreen(),
        '/patrol-home': (_) => const PatrolHomeScreen(),
        '/patrol-accident-map': (_) => const PatrolAccidentMapScreen(),
        '/patrol-terms': (_) => const PatrolTermsScreen(),
        '/patrol-privacy': (_) => const PatrolPrivacyScreen(),
        '/patrol-register': (_) => const PatrolRegistrationScreen(),
        '/accident': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          return AccidentDetectedScreen(alreadyReported: args?['alreadyReported'] == true);
        },
        '/emergency-sent': (_) => const EmergencyAlertSentScreen(),
        '/voice-assistant': (_) => const VoiceAssistantScreen(),
      },
    );
  }
}
