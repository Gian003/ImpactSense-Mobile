import 'package:flutter/material.dart';
import 'package:impactsense/core/theme/app_theme.dart';
import 'package:impactsense/screens/on_boarding_screen.dart';
import 'package:impactsense/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      title: 'ImpactSense',
      debugShowCheckedModeBanner: false,
      home: SplashScreenWrapper(),
      routes: {'/onboarding': (context) => const OnBoardingScreen()},
    );
  }
}
