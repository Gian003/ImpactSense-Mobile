import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/screens/settings/add_contact_screen.dart';

class EmergencyContact {
  final String name;
  final String type;

  const EmergencyContact({required this.name, required this.type});
}

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  final List<EmergencyContact> _contacts = const [
    EmergencyContact(name: 'PNP (911)', type: 'Primary contact'),
    EmergencyContact(name: 'PAPA', type: 'Secondary contact'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
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
            ),

            // Logo
            Center(
              child: Image.asset(
                'assets/logo/logo.png',
                height: 90,
                width: 90,
              ),
            ),

            const SizedBox(height: 16),

            // Title
            const Center(
              child: Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ContactCard(
                  contact: _contacts[i],
                  primaryColor: _primaryColor,
                ),
              ),
            ),

            // Add contacts button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddContactScreen(),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBFD4DA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _primaryColor.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.circlePlus,
                          color: Colors.black87, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Add contacts',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.primaryColor,
  });

  final EmergencyContact contact;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.phone,
              color: Colors.green, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.name,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '(${contact.type})',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
