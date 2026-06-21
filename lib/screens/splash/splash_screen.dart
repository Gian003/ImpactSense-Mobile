import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:impactsense/core/services/session_service.dart';

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  SplashScreenWrapperState createState() => SplashScreenWrapperState();
}

class SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _hasError = false;
  String _errorMessage = '';

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      await _navigateBasedOnAuth();
    } catch (error) {
      if (kDebugMode) print('Initialization error: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Initialization failed: ${error.toString()}';
        });
      }
    }
  }

  Future<void> _navigateBasedOnAuth() async {
    final loggedIn = await SessionService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      final role = await SessionService.getRole();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        role == 'patrol' ? '/patrol-home' : '/home',
      );
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _retryInitializeApp() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      hasError: _hasError,
      errorMessage: _errorMessage,
      onRetry: _retryInitializeApp,
    );
  }
}

class SplashScreen extends StatelessWidget {
  final bool hasError;
  final String errorMessage;
  final VoidCallback? onRetry;

  const SplashScreen({
    super.key,
    required this.hasError,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 30),
              if (hasError) ..._buildErrorState() else ..._buildLoadingState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Image.asset(
            'assets/logo/logo.png',
            width: 200,
            height: 200,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.green[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image, size: 80, color: Colors.grey),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildLoadingState() {
    return [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 1),
        builder: (context, value, child) {
          return SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              backgroundColor: Colors.grey[300],
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildErrorState() {
    return [
      const Icon(Icons.error_outline, size: 60, color: Colors.red),
      const SizedBox(),
      Text(
        'Initialization Failed',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: Colors.grey[700],
        ),
      ),
      const SizedBox(),
      Text(
        errorMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: Colors.grey[600],
        ),
      ),
      const SizedBox(),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: Text(
          'Retry',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF4CAF50),
        ),
      ),
    ];
  }
}
