import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/widgets/app_input_field.dart';
import 'package:impactsense/widgets/role_toggle.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  int _selectedTab = 0;
  bool _passwordVisible = false;
  bool _repeatPasswordVisible = false;
  bool _keepLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              Image.asset('assets/logo/logo.png', height: 110, width: 110),

              const SizedBox(height: 32),

              RoleToggle(
                selectedIndex: _selectedTab,
                onChanged: (i) => setState(() => _selectedTab = i),
              ),

              const SizedBox(height: 20),

              const Text(
                'Secure your journey. Log in to activate.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              AppInputField(hint: 'Email Address', prefixIcon: FontAwesomeIcons.envelope),

              const SizedBox(height: 12),

              AppInputField(
                hint: 'Password',
                prefixIcon: FontAwesomeIcons.key,
                obscureText: !_passwordVisible,
                suffixIcon: _passwordVisible
                    ? FontAwesomeIcons.eye
                    : FontAwesomeIcons.eyeSlash,
                onSuffixTap: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),

              const SizedBox(height: 12),

              AppInputField(
                hint: 'Repeat Password',
                prefixIcon: FontAwesomeIcons.key,
                obscureText: !_repeatPasswordVisible,
                suffixIcon: _repeatPasswordVisible
                    ? FontAwesomeIcons.eye
                    : FontAwesomeIcons.eyeSlash,
                onSuffixTap: () => setState(
                    () => _repeatPasswordVisible = !_repeatPasswordVisible),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Checkbox(
                    value: _keepLoggedIn,
                    onChanged: (v) =>
                        setState(() => _keepLoggedIn = v ?? false),
                    activeColor: _primaryColor,
                    side: const BorderSide(color: Colors.black54),
                  ),
                  const Text(
                    'Keep me Logged in',
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset coming soon.',
                            style: TextStyle(fontFamily: 'Montserrat')),
                        duration: Duration(seconds: 2),
                      ),
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    _selectedTab == 0 ? '/home' : '/patrol-home',
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
