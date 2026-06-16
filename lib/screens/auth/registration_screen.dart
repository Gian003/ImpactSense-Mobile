import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  int _selectedTab = 0;
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
                'Fill in your patrollers details to stay safe and connected.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              // Tab switcher
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _primaryColor),
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? _primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Riders',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _selectedTab == 0
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? _primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Patrols',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _selectedTab == 1
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _InputField(
                hint: 'Email Address',
                prefixIcon: FontAwesomeIcons.envelope,
              ),

              const SizedBox(height: 12),

              _InputField(
                hint: 'Contact Number',
                prefixIcon: FontAwesomeIcons.phone,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 12),

              _InputField(
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

              _InputField(
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
  });

  final String hint;
  final FaIconData prefixIcon;
  final bool obscureText;
  final FaIconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;

  static const _primaryColor = Color(0xFF1A6B78);

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          color: Colors.grey[500],
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: FaIcon(prefixIcon, color: _primaryColor, size: 18),
        ),
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FaIcon(suffixIcon, color: Colors.grey[500], size: 18),
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _primaryColor.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _primaryColor.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
