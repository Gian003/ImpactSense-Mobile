import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PatrolTermsScreen extends StatefulWidget {
  const PatrolTermsScreen({super.key});

  @override
  State<PatrolTermsScreen> createState() => _PatrolTermsScreenState();
}

class _PatrolTermsScreenState extends State<PatrolTermsScreen> {
  static const _primaryColor = Color(0xFF1A6B78);
  static const _cardBg = Color(0xFFCCE4EA);
  static const _bg = Color(0xFFF0F2F4);

  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Icon + subtitle
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.fileLines,
                              color: _primaryColor,
                              size: 48,
                            ),
                            Positioned(
                              right: -6,
                              bottom: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: _primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.check,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Please read these Terms & Conditions carefully before using Impactsense',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Clauses box
                    Container(
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Column(
                        children: [
                          _Clause(
                            number: '1.',
                            text:
                                'By using ImpactSense, you agree to follow these Terms and Conditions. The app is designed to provide accident detection, GPS tracking, and emergency alert features to support user safety.',
                          ),
                          Divider(height: 1, color: Color(0xFF9BBEC8)),
                          _Clause(
                            number: '2.',
                            text:
                                'Users must provide accurate information, keep their account secure, and use the app responsibly. ImpactSense is not a substitute for official emergency services, and delays or errors in alerts may occur.',
                          ),
                          Divider(height: 1, color: Color(0xFF9BBEC8)),
                          _Clause(
                            number: '3.',
                            text:
                                'The developers are not liable for any damages, data inaccuracies, or system issues resulting from the use of the application. We reserve the right to update or modify the app and these terms at any time.\nContinued use of ImpactSense means you accept these Terms and Conditions.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _agreed,
                          onChanged: (v) =>
                              setState(() => _agreed = v ?? false),
                          activeColor: _primaryColor,
                          side: BorderSide(color: Colors.grey[500]!),
                        ),
                        const Expanded(
                          child: Text(
                            'I have read and agree to the Terms & Conditions',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Accept button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _agreed ? () => Navigator.pop(context) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          disabledBackgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Accept & Continue',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Clause extends StatelessWidget {
  const _Clause({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Colors.black87,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: '$number  ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
