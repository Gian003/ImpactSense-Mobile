import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/screens/settings/emergency_contacts_screen.dart';
import 'package:impactsense/screens/settings/privacy_policy_screen.dart';
import 'package:impactsense/screens/settings/terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  bool _pushNotifications = true;
  bool _locationAccess = true;
  bool _contactAccess = true;

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF2A4A5A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want\nto Log out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // No
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'No',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Yes
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/onboarding',
                          (route) => false,
                        );
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Yes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap:
                        widget.onBack ?? () => Navigator.pop(context),
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
                  const Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),

            // ── Scrollable content ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile card
                    _OutlineCard(
                      child: Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/pictures/profile pic.png',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey[300],
                                child: const FaIcon(
                                  FontAwesomeIcons.solidUser,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rester',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Rester@gmail.com',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.penToSquare,
                                size: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Emergency contact
                    _OutlineCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmergencyContactsScreen(),
                        ),
                      ),
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.phone,
                              color: _primaryColor, size: 18),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Emergency contact',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Colors.black45),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Edit Profile button
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBFD4DA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Edit Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notifications
                    const _SectionLabel(text: 'Notifications'),
                    const SizedBox(height: 8),
                    _OutlineCard(
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Push Notifications',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _LabeledSwitch(
                            value: _pushNotifications,
                            onChanged: (v) => setState(
                                () => _pushNotifications = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Permissions
                    const _SectionLabel(text: 'Permissions'),
                    const SizedBox(height: 8),
                    _OutlineCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Location access',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              _LabeledSwitch(
                                value: _locationAccess,
                                onChanged: (v) => setState(
                                    () => _locationAccess = v),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Contact access',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              _LabeledSwitch(
                                value: _contactAccess,
                                onChanged: (v) => setState(
                                    () => _contactAccess = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // About
                    const _SectionLabel(text: 'About'),
                    const SizedBox(height: 8),
                    _OutlineCard(
                      child: Column(
                        children: [
                          _AboutRow(
                              label: 'Terms & Conditions',
                              onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const TermsScreen()),
                                  )),
                          const Divider(height: 20),
                          _AboutRow(
                              label: 'Privacy Policy',
                              onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const PrivacyPolicyScreen()),
                                  )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Log out
                    _OutlineCard(
                      onTap: () => _showLogoutDialog(context),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _primaryColor, width: 1.5),
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.arrowRight,
                              color: _primaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Log out',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
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

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class _OutlineCard extends StatelessWidget {
  const _OutlineCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1A6B78).withValues(alpha: 0.35),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _LabeledSwitch extends StatelessWidget {
  const _LabeledSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF1A6B78),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[400],
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(
          value ? 'on' : 'off',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: value
                ? const Color(0xFF1A6B78)
                : Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              size: 13, color: Colors.black45),
        ],
      ),
    );
  }
}
