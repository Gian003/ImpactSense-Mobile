import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/core/services/api_client.dart';
import 'package:impactsense/core/services/session_service.dart';
import 'package:impactsense/screens/riders/settings/add_contact_screen.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      final token = await SessionService.getToken();
      if (token == null) return;
      final res = await ApiClient.get('rider/emergency-contacts', token: token);
      if (res['success'] == true && mounted) {
        final data = res['data'] as List<dynamic>? ?? [];
        setState(() {
          _contacts = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {
      // Keep list empty on error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) return;
      await ApiClient.delete('rider/emergency-contacts/$id', token: token);
      await _loadContacts();
    } catch (_) {}
  }

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

            Center(child: Image.asset('assets/logo/logo.png',
                height: 90, width: 90)),

            const SizedBox(height: 16),

            const Center(
              child: Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontFamily: 'Montserrat', fontSize: 22,
                  fontWeight: FontWeight.bold, color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _contacts.isEmpty
                      ? const Center(
                          child: Text(
                            'No emergency contacts yet.\nTap "Add contacts" below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13, color: Colors.black45,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _contacts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _ContactCard(
                            contact: _contacts[i],
                            primaryColor: _primaryColor,
                            onDelete: () => _delete(
                                _contacts[i]['id'] as int),
                          ),
                        ),
            ),

            // Add contacts button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AddContactScreen()));
                  _loadContacts(); // refresh after returning
                },
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
                      Text('Add contacts',
                          style: TextStyle(
                            fontFamily: 'Montserrat', fontSize: 15,
                            fontWeight: FontWeight.w600, color: Colors.black87,
                          )),
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
    required this.onDelete,
  });

  final Map<String, dynamic> contact;
  final Color primaryColor;
  final VoidCallback onDelete;

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
          const FaIcon(FontAwesomeIcons.phone, color: Colors.green, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['name'] as String? ?? '',
                  style: const TextStyle(
                    fontFamily: 'Montserrat', fontSize: 14,
                    fontWeight: FontWeight.bold, color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${contact['phone_number'] ?? ''}${contact['relationship'] != null ? '  ·  ${contact['relationship']}' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat', fontSize: 12, color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const FaIcon(FontAwesomeIcons.trashCan,
                color: Colors.red, size: 16),
          ),
        ],
      ),
    );
  }
}
