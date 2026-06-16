import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  bool _agreed = false;

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
                    'Privacy Policy',
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
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2A4A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.shieldHalved,
                                    color: Colors.white,
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
                            'Your privacy is important to us. Please read our Privacy  Policy below',
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

                    // ── Policy content box ────────────────────────────────
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
                        children: [
                          // Clause 1
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(14, 14, 14, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '1. ',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Expanded(
                                  child: Text(
                                    'ImpactSense collects personal information such as your name, '
                                    'contact details, address, and real-time location to provide '
                                    'essential features like accident detection, GPS tracking, and '
                                    'emergency alerts. Your data is used only for app functionality '
                                    'and is kept secure and confidential.',
                                    style: TextStyle(
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

                          Divider(
                              height: 1,
                              color: _primaryColor.withValues(alpha: 0.3)),

                          // Clause 2
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(14, 14, 14, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '2. ',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Expanded(
                                  child: Text(
                                    'We do not sell or share your information with third parties, '
                                    'except when necessary to notify emergency contacts, assist '
                                    'responders, or comply with legal requirements. Users may '
                                    'request to access, update, or delete their data at any time.',
                                    style: TextStyle(
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

                          Divider(
                              height: 1,
                              color: _primaryColor.withValues(alpha: 0.3)),

                          // Closing clause (no number)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
                            child: Text(
                              'By using ImpactSense, you agree to this Privacy Policy. '
                              'Updates may be made periodically, and continued use of the '
                              'app means acceptance of any changes.',
                              style: TextStyle(
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
                            'I have read and agree to the Privacy Policy',
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
