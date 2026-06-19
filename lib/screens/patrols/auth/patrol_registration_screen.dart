import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/widgets/app_input_field.dart';
import 'package:impactsense/widgets/role_toggle.dart';

class PatrolRegistrationScreen extends StatefulWidget {
  const PatrolRegistrationScreen({super.key});

  @override
  State<PatrolRegistrationScreen> createState() =>
      _PatrolRegistrationScreenState();
}

class _PatrolRegistrationScreenState extends State<PatrolRegistrationScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  bool _passwordVisible = false;
  bool _repeatPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Center(
                child: Image.asset(
                  'assets/logo/logo.png',
                  height: 90,
                  width: 90,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Create Account',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Fill in your patrollers details to stay safe and connected.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              // Role toggle — Patrols selected; tapping Riders goes to rider registration
              RoleToggle(
                selectedIndex: 1,
                onChanged: (i) {
                  if (i == 0) {
                    Navigator.pushReplacementNamed(context, '/register');
                  }
                },
              ),

              const SizedBox(height: 24),

              // Name row
              Row(
                children: [
                  Expanded(
                    child: AppInputField(
                      hint: 'First Name',
                      prefixIcon: FontAwesomeIcons.userGroup,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppInputField(
                      hint: 'Last Name',
                      prefixIcon: FontAwesomeIcons.userGroup,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              AppInputField(
                hint: 'Email Address',
                prefixIcon: FontAwesomeIcons.envelope,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 12),

              AppInputField(
                hint: 'Contact Number',
                prefixIcon: FontAwesomeIcons.phone,
                keyboardType: TextInputType.phone,
              ),

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

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/otp-verify'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
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
