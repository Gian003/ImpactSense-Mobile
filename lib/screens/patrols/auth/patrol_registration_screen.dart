import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/core/services/auth_service.dart';
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

  // Toggle: false = Sign Up form, true = Log In form
  bool _showLogin       = false;
  bool _passwordVisible = false;
  bool _repeatVisible   = false;
  bool _loading         = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Patrol accounts are pre-created by admins — sign-up redirects to login
  void _onSignUp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Account Created by Admin',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Patrol accounts are created by your administrator.\n\n'
          'Please contact your supervisor to receive your credentials, '
          'then use the Log in button to access your account.',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _showLogin = true);
            },
            child: const Text('Go to Log in',
                style: TextStyle(fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold, color: Color(0xFF1A6B78))),
          ),
        ],
      ),
    );
  }

  Future<void> _onLogin() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter your email and password.');
      return;
    }

    setState(() => _loading = true);

    final result = await AuthService.loginPatrol(
        email: email, password: password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/patrol-home');
    } else {
      _showSnack(result.message);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Montserrat')),
      backgroundColor: Colors.red[700],
      duration: const Duration(seconds: 3),
    ));
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

              Center(child: Image.asset('assets/logo/logo.png',
                  height: 90, width: 90)),

              const SizedBox(height: 20),

              Text(
                _showLogin ? 'Patrol Sign In' : 'Create Account',
                style: const TextStyle(
                  fontFamily: 'Montserrat', fontSize: 22,
                  fontWeight: FontWeight.bold, color: Colors.black87,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Fill in your patrollers details to stay safe and connected.',
                style: TextStyle(
                  fontFamily: 'Montserrat', fontSize: 13,
                  fontWeight: FontWeight.bold, color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              RoleToggle(
                selectedIndex: 1,
                onChanged: (i) {
                  if (i == 0) Navigator.pushReplacementNamed(context, '/register');
                },
              ),

              const SizedBox(height: 24),

              if (!_showLogin) ...[
                // ── Sign Up form (design layout) ─────────────────────────
                Row(children: [
                  Expanded(child: AppInputField(
                    hint: 'First Name',
                    controller: _firstNameCtrl,
                    prefixIcon: FontAwesomeIcons.userGroup,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: AppInputField(
                    hint: 'Last Name',
                    controller: _lastNameCtrl,
                    prefixIcon: FontAwesomeIcons.userGroup,
                  )),
                ]),
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
                      ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                  onSuffixTap: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
                const SizedBox(height: 12),
                AppInputField(
                  hint: 'Repeat Password',
                  controller: _confirmCtrl,
                  prefixIcon: FontAwesomeIcons.key,
                  obscureText: !_repeatVisible,
                  suffixIcon: _repeatVisible
                      ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                  onSuffixTap: () =>
                      setState(() => _repeatVisible = !_repeatVisible),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onSignUp,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Sign Up',
                        style: TextStyle(fontFamily: 'Montserrat',
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _showLogin = true),
                    child: const Text(
                      'Already have an account? Log in',
                      style: TextStyle(fontFamily: 'Montserrat',
                          fontSize: 13, color: Color(0xFF1A6B78)),
                    ),
                  ),
                ),

              ] else ...[
                // ── Log In form ───────────────────────────────────────────
                AppInputField(
                  hint: 'Email Address',
                  controller: _emailCtrl,
                  prefixIcon: FontAwesomeIcons.envelope,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                AppInputField(
                  hint: 'Password',
                  controller: _passwordCtrl,
                  prefixIcon: FontAwesomeIcons.key,
                  obscureText: !_passwordVisible,
                  suffixIcon: _passwordVisible
                      ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                  onSuffixTap: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _onLogin,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Sign In',
                            style: TextStyle(fontFamily: 'Montserrat',
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _showLogin = false),
                    child: const Text(
                      'Don\'t have an account? Sign up',
                      style: TextStyle(fontFamily: 'Montserrat',
                          fontSize: 13, color: Color(0xFF1A6B78)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
