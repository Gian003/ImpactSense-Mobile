import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/core/services/api_client.dart';
import 'package:impactsense/core/services/session_service.dart';
import 'package:impactsense/widgets/app_input_field.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  bool _saving = false;

  final _nameCtrl         = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _relationshipCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name  = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name and phone number are required.',
            style: TextStyle(fontFamily: 'Montserrat')),
      ));
      return;
    }

    setState(() => _saving = true);

    try {
      final token = await SessionService.getToken();
      if (token == null) return;

      final res = await ApiClient.post('rider/emergency-contacts', {
        'name'         : name,
        'phone_number' : phone,
        if (_relationshipCtrl.text.trim().isNotEmpty)
          'relationship' : _relationshipCtrl.text.trim(),
      }, token: token);

      if (!mounted) return;

      if (res['success'] == true) {
        Navigator.pop(context); // return to contacts list (which will refresh)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Failed to save.',
              style: const TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Colors.red[700],
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connection error.',
              style: TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(Icons.chevron_left,
                        size: 22, color: Colors.black54),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Image.asset('assets/logo/logo.png',
                        height: 90, width: 90)),

                    const SizedBox(height: 12),

                    const Center(
                      child: Text(
                        'Add Emergency Contact',
                        style: TextStyle(
                          fontFamily: 'Montserrat', fontSize: 20,
                          fontWeight: FontWeight.bold, color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Center(
                      child: Text(
                        'This person will be alerted if an accident is detected.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montserrat', fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    AppInputField(
                      hint: 'Full Name',
                      controller: _nameCtrl,
                      prefixIcon: FontAwesomeIcons.userGroup,
                    ),

                    const SizedBox(height: 12),

                    AppInputField(
                      hint: 'Phone Number',
                      controller: _phoneCtrl,
                      prefixIcon: FontAwesomeIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 12),

                    AppInputField(
                      hint: 'Relationship (e.g. Mother, Friend)',
                      controller: _relationshipCtrl,
                      prefixIcon: FontAwesomeIcons.heart,
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Save Contact',
                                style: TextStyle(
                                  fontFamily: 'Montserrat', fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )),
                      ),
                    ),

                    const SizedBox(height: 20),
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
