import 'package:flutter/material.dart';
import 'package:impactsense/screens/auth/authenticaion_verify.dart';
import 'package:impactsense/screens/auth/device_synced_screen.dart';
import 'package:impactsense/screens/auth/login_screen.dart';
import 'package:impactsense/screens/auth/otp_verify.dart';
import 'package:impactsense/screens/auth/personal_information_screen.dart';
import 'package:impactsense/screens/auth/registration_screen.dart';
import 'package:impactsense/screens/emergency/accident_detected_screen.dart';
import 'package:impactsense/screens/emergency/emergency_alert_sent_screen.dart';
import 'package:impactsense/screens/home/home_screen.dart';
import 'package:impactsense/screens/emergency/voice_assistant_screen.dart';
import 'package:impactsense/screens/onboarding/on_boarding_screen.dart';
import 'package:impactsense/screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/accident': (_) => const AccidentDetectedScreen(),
        '/emergency-sent': (_) => const EmergencyAlertSentScreen(),
        '/voice-assistant': (_) => const VoiceAssistantScreen(),
      },
    );
  }
}
