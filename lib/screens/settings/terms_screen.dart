import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  bool _agreed = false;

  static const _terms = [
    (
      number: '1.',
      text:
          'By using ImpactSense, you agree to follow these Terms and Conditions. '
              'The app is designed to provide accident detection, GPS tracking, '
              'and emergency alert features to support user safety.',
    ),
    (
      number: '2.',
      text:
          'Users must provide accurate information, keep their account secure, '
              'and use the app responsibly. ImpactSense is not a substitute for '
              'official emergency services, and delays or errors in alerts may occur.',
    ),
    (
      number: '3.',
      text:
          'The developers are not liable for any damages, data inaccuracies, '
              'or system issues resulting from the use of the application. '
              'We reserve the right to update or modify the app and these terms '
              'at any time.\nContinued use of ImpactSense means you accept these '
              'Terms and Conditions.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.chevron_left,
                          size: 22, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Header row ────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Document icon with check badge
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCFE4E8),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _primaryColor
                                          .withValues(alpha: 0.4)),
                                ),
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.fileLines,
                                    color: _primaryColor,
                                    size: 26,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const FaIcon(
                                    FontAwesomeIcons.check,
                                    color: Colors.white,
                                    size: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Text(
                            'Please read  these  Terms & Conditions carefully before using Impactsense',
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

                    // ── Terms box ─────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFE4E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _primaryColor.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_terms.length, (i) {
                          final term = _terms[i];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    14, 14, 14, 12),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      term.number,
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        term.text,
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 13,
                                          color: Colors.black87,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < _terms.length - 1)
                                Divider(
                                  height: 1,
                                  color: _primaryColor.withValues(alpha: 0.3),
                                ),
                            ],
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Checkbox ──────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _agreed,
                          onChanged: (v) =>
                              setState(() => _agreed = v ?? false),
                          activeColor: _primaryColor,
                          side: const BorderSide(color: Colors.black54),
                          visualDensity: VisualDensity.compact,
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

                    const SizedBox(height: 24),

                    // ── Accept & Continue button ───────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _agreed ? () => Navigator.pop(context) : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _primaryColor,
                          disabledBackgroundColor:
                              _primaryColor.withValues(alpha: 0.4),
                          disabledForegroundColor: Colors.white70,
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
                            fontSize: 16,
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
