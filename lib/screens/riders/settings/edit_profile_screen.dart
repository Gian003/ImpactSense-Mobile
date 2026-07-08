import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/core/services/rider_profile_service.dart';
import 'package:impactsense/widgets/app_input_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  late final _nameCtrl = TextEditingController(text: widget.user['full_name'] as String?);
  late final _emailCtrl = TextEditingController(text: widget.user['email'] as String?);
  late final _phoneCtrl = TextEditingController(text: widget.user['phone_number'] as String?);
  late final _addressCtrl = TextEditingController(text: widget.user['address'] as String?);

  DateTime? _dateOfBirth;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final dob = widget.user['date_of_birth'] as String?;
    if (dob != null && dob.isNotEmpty) {
      _dateOfBirth = DateTime.tryParse(dob);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      helpText: 'Select Date of Birth',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (name.isEmpty || email.isEmpty) {
      _showError('Full name and email are required.');
      return;
    }

    setState(() => _saving = true);

    final dob = _dateOfBirth != null
        ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
        : null;

    final result = await RiderProfileService.updateProfile(
      fullName: name,
      email: email,
      phoneNumber: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      dateOfBirth: dob,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      Navigator.pop(context, result.user);
    } else {
      _showError(result.message);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Montserrat')),
      backgroundColor: Colors.red[700],
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  const Expanded(
                    child: Text(
                      'Edit Profile',
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppInputField(
                      hint: 'Full Name',
                      controller: _nameCtrl,
                      prefixIcon: FontAwesomeIcons.user,
                    ),
                    const SizedBox(height: 12),
                    AppInputField(
                      hint: 'Email',
                      controller: _emailCtrl,
                      prefixIcon: FontAwesomeIcons.envelope,
                      keyboardType: TextInputType.emailAddress,
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
                      hint: 'Address',
                      controller: _addressCtrl,
                      prefixIcon: FontAwesomeIcons.locationDot,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickDateOfBirth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primaryColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(children: [
                          const FaIcon(FontAwesomeIcons.cakeCandles,
                              color: _primaryColor, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _dateOfBirth != null
                                ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                : 'Date of Birth',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              color: _dateOfBirth != null ? Colors.black87 : Colors.grey[500],
                            ),
                          ),
                        ]),
                      ),
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
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
