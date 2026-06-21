import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/core/services/auth_service.dart';
import 'package:impactsense/widgets/app_input_field.dart';
import 'package:impactsense/widgets/role_toggle.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  bool _passwordVisible = false;
  bool _repeatPasswordVisible = false;
  bool _loading = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Full name, email, and password are required.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }

    setState(() => _loading = true);

    final result = await AuthService.registerRider(
      fullName: name,
      email: email,
      password: password,
      passwordConfirmation: confirm,
      phoneNumber: phone.isNotEmpty ? phone : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showError(result.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Montserrat')),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
                  height: 110,
                  width: 110,
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
                'Fill in your details to stay safe and connected.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              RoleToggle(
                selectedIndex: 0,
                onChanged: (i) {
                  if (i == 1) {
                    Navigator.pushReplacementNamed(context, '/patrol-register');
                  }
                },
              ),

              const SizedBox(height: 24),

              AppInputField(
                hint: 'Full Name',
                controller: _nameCtrl,
                prefixIcon: FontAwesomeIcons.user,
              ),

              const SizedBox(height: 12),

              AppInputField(
                hint: 'Email Address',
                controller: _emailCtrl,
                prefixIcon: FontAwesomeIcons.envelope,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 12),

              AppInputField(
                hint: 'Contact Number',
                controller: _phoneCtrl,
                prefixIcon: FontAwesomeIcons.phone,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 12),

              AppInputField(
                hint: 'Password',
                controller: _passwordCtrl,
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
                controller: _confirmCtrl,
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
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
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
