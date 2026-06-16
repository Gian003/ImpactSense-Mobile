import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/screens/map/live_navigation_screen.dart';
import 'package:impactsense/screens/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _primaryColor = Color(0xFF1A6B78);
  int _currentNavIndex = 0;

  void _showDeviceStatusHelp() {
    showDialog(context: context, builder: (_) => const _DeviceStatusDialog());
  }

  void _showMaintenanceHelp() {
    showDialog(context: context, builder: (_) => const _MaintenanceDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          // Tab 0 — Home
          SafeArea(
            child: Column(
              children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Image.asset('assets/logo/logo.png', height: 38, width: 38),
                  const SizedBox(width: 10),
                  const Text(
                    'Hello, Rester!',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _primaryColor,
                    child: const Text(
                      'R',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // ── Scrollable body ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Device Status
                    _SectionHeader(
                      title: 'Device Status',
                      onHelpTap: _showDeviceStatusHelp,
                    ),
                    const SizedBox(height: 8),
                    _StatusCard(
                      icon: FontAwesomeIcons.circleCheck,
                      iconColor: Colors.green,
                      label: 'Helmet Status:',
                      value: 'Connected',
                      indicator: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _StatusCard(
                      icon: FontAwesomeIcons.burst,
                      iconColor: Colors.orange,
                      label: 'Collision Detection',
                      indicator: Colors.yellow,
                    ),
                    const SizedBox(height: 8),
                    _StatusCard(
                      icon: FontAwesomeIcons.batteryQuarter,
                      iconColor: Colors.red,
                      label: 'Helmet Battery:',
                      value: '10%',
                      indicator: Colors.red,
                    ),

                    const SizedBox(height: 16),

                    // GPS Status
                    const _SectionHeader(title: 'GPS Status'),
                    const SizedBox(height: 8),
                    _InfoCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[300],
                            child: const FaIcon(
                              FontAwesomeIcons.solidUser,
                              size: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: 'Active: ',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Location is being tracked',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(const TextSpan(children: [
                            TextSpan(
                              text: 'Recommended Speed',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: ': 80 kph',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ])),
                          const SizedBox(height: 4),
                          Text.rich(const TextSpan(children: [
                            TextSpan(
                              text: 'Current Speed',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: ': 60 kph',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ])),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Map placeholder
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 160,
                        color: Colors.grey[300],
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.map,
                                  size: 36, color: Colors.grey[500]),
                              const SizedBox(height: 6),
                              Text(
                                'Map goes here',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // System Maintenance
                    _SectionHeader(
                      title: 'System Maintenance',
                      onHelpTap: _showMaintenanceHelp,
                    ),
                    const SizedBox(height: 8),
                    _MaintenanceButton(
                      icon: FontAwesomeIcons.mobileScreen,
                      label: 'Live Navigation',
                      onTap: () => setState(() => _currentNavIndex = 1),
                    ),
                    const SizedBox(height: 8),
                    _MaintenanceButton(
                      icon: FontAwesomeIcons.microphone,
                      label: 'Voice Assistant',
                      onTap: () => Navigator.pushNamed(
                          context, '/voice-assistant'),
                    ),
                    const SizedBox(height: 8),
                    _MaintenanceButton(
                      icon: FontAwesomeIcons.bell,
                      label: 'Collision Detection',
                      onTap: () =>
                          Navigator.pushNamed(context, '/accident'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

          // Tab 1 — Live Navigation
          LiveNavigationScreen(
            onBack: () => setState(() => _currentNavIndex = 0),
          ),

          // Tab 2 — Settings
          SettingsScreen(
            onBack: () => setState(() => _currentNavIndex = 0),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onHelpTap});

  final String title;
  final VoidCallback? onHelpTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        if (onHelpTap != null)
          GestureDetector(
            onTap: onHelpTap,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xFF1A6B78),
              child: Text(
                '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Status card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.value,
    required this.indicator,
  });

  final FaIconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final Color indicator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A6B78).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (value != null)
                TextSpan(
                  text: '   $value',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
            ])),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: indicator,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic info card ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A6B78).withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

// ── Maintenance button ────────────────────────────────────────────────────────

class _MaintenanceButton extends StatelessWidget {
  const _MaintenanceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFCFE4E8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF1A6B78).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: const Color(0xFF1A6B78), size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.locationDot,
    FontAwesomeIcons.gear,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A6B78),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final selected = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                _items[i],
                color: Colors.white,
                size: selected ? 22 : 20,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Device Status help dialog ─────────────────────────────────────────────────

class _DeviceStatusDialog extends StatelessWidget {
  const _DeviceStatusDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Status',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Each Color on the device indicates each statuses:',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _ColorIndicatorRow(
              color: Colors.green,
              text: 'Green color  for the device is connected',
            ),
            const SizedBox(height: 12),
            _ColorIndicatorRow(
              color: Colors.yellow,
              text: 'Yellow color for the device is in danger of collision',
            ),
            const SizedBox(height: 12),
            _ColorIndicatorRow(
              color: Colors.red,
              text: 'Red color for the device is in danger of collision',
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorIndicatorRow extends StatelessWidget {
  const _ColorIndicatorRow({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Maintenance help dialog ───────────────────────────────────────────────────

class _MaintenanceDialog extends StatelessWidget {
  const _MaintenanceDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maintenance Status',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Each Option on the device indicates each statuses:',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _MaintenanceRow(
              label: 'Live Navigation',
              description:
                  'if the location is centered the live navigation is working',
            ),
            const SizedBox(height: 12),
            _MaintenanceRow(
              label: 'Voice Assistant',
              description:
                  'if the call are heard the the device\'s speaker it is working',
            ),
            const SizedBox(height: 12),
            _MaintenanceRow(
              label: 'Collision Detection',
              description:
                  'if the detection is working, the device should be vibrating and turning yellow',
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceRow extends StatelessWidget {
  const _MaintenanceRow({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: '$label: ',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        TextSpan(
          text: description,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ]),
    );
  }
}

