import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/core/services/api_client.dart';
import 'package:impactsense/core/services/auth_service.dart';
import 'package:impactsense/core/services/psgc_service.dart';
import 'package:impactsense/core/services/session_service.dart';
import 'package:impactsense/widgets/app_input_field.dart';
import 'package:impactsense/widgets/psgc_location_widgets.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  // Name controllers
  final _firstNameCtrl  = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _suffixCtrl     = TextEditingController();

  // Contact controllers (pre-filled from registration args)
  final _contactCtrl          = TextEditingController();
  final _emergencyPersonCtrl  = TextEditingController();
  final _emergencyNumberCtrl  = TextEditingController();
  final _deviceIdCtrl         = TextEditingController();

  // Date of birth — picked via date picker
  DateTime? _dateOfBirth;

  // Location state (PSGC dropdowns)
  List<PsgcLocation> _provinces      = [];
  List<PsgcLocation> _municipalities = [];
  List<PsgcLocation> _barangays      = [];

  PsgcLocation? _selectedProvince;
  PsgcLocation? _selectedMunicipality;
  PsgcLocation? _selectedBarangay;

  bool _loadingProvinces      = true;
  bool _loadingMunicipalities = false;
  bool _loadingBarangays      = false;
  bool _saving                = false;

  // Credentials passed from Registration → OTP → here
  String _email    = '';
  String _phone    = '';
  String _password = '';
  String _confirm  = '';

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _email    = args['email']   as String? ?? '';
      _phone    = args['phone']   as String? ?? '';
      _password = args['password'] as String? ?? '';
      _confirm  = args['confirm']  as String? ?? '';
      // Pre-fill contact number from registration
      if (_contactCtrl.text.isEmpty && _phone.isNotEmpty) {
        _contactCtrl.text = _phone;
      }
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _suffixCtrl.dispose();
    _contactCtrl.dispose();
    _emergencyPersonCtrl.dispose();
    _emergencyNumberCtrl.dispose();
    _deviceIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await PsgcService.fetchProvinces();
      if (mounted) setState(() { _provinces = provinces; _loadingProvinces = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _onProvinceChanged(PsgcLocation? province) async {
    setState(() {
      _selectedProvince     = province;
      _selectedMunicipality = null;
      _selectedBarangay     = null;
      _municipalities       = [];
      _barangays            = [];
      _loadingMunicipalities = province != null;
    });
    if (province == null) return;
    try {
      final list = await PsgcService.fetchMunicipalities(province.code);
      if (mounted) setState(() { _municipalities = list; _loadingMunicipalities = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMunicipalities = false);
    }
  }

  Future<void> _onMunicipalityChanged(PsgcLocation? muni) async {
    setState(() {
      _selectedMunicipality = muni;
      _selectedBarangay     = null;
      _barangays            = [];
      _loadingBarangays     = muni != null;
    });
    if (muni == null) return;
    try {
      final list = await PsgcService.fetchBarangays(muni.code);
      if (mounted) setState(() { _barangays = list; _loadingBarangays = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingBarangays = false);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
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
    final first  = _firstNameCtrl.text.trim();
    final last   = _lastNameCtrl.text.trim();
    final middle = _middleNameCtrl.text.trim();
    final suffix = _suffixCtrl.text.trim();

    if (first.isEmpty || last.isEmpty) {
      _showError('First name and last name are required.');
      return;
    }

    final fullName = [first, if (middle.isNotEmpty) middle, last,
                      if (suffix.isNotEmpty) suffix].join(' ');

    // Build full address string from selected PSGC locations
    final addressParts = [
      _selectedBarangay?.name,
      _selectedMunicipality?.name,
      _selectedProvince?.name,
    ].whereType<String>().toList();
    final address = addressParts.isNotEmpty ? addressParts.join(', ') : null;

    // Format date of birth as YYYY-MM-DD
    final dob = _dateOfBirth != null
        ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2,'0')}-${_dateOfBirth!.day.toString().padLeft(2,'0')}'
        : null;

    setState(() => _saving = true);

    final result = await AuthService.registerRider(
      fullName             : fullName,
      email                : _email,
      password             : _password,
      passwordConfirmation : _confirm,
      phoneNumber          : _contactCtrl.text.trim().isNotEmpty
                             ? _contactCtrl.text.trim()
                             : _phone,
      address              : address,
      dateOfBirth          : dob,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      final token = await SessionService.getToken();

      // Save emergency contact if provided during registration
      final emergencyName  = _emergencyPersonCtrl.text.trim();
      final emergencyPhone = _emergencyNumberCtrl.text.trim();
      if (token != null && emergencyName.isNotEmpty && emergencyPhone.isNotEmpty) {
        try {
          await ApiClient.post('rider/emergency-contacts', {
            'name'         : emergencyName,
            'phone_number' : emergencyPhone,
            'relationship' : 'Emergency Contact',
          }, token: token);
        } catch (_) {
          // Non-fatal — contact can be added later
        }
      }

      // Pair helmet if a device ID was entered
      final deviceId = _deviceIdCtrl.text.trim();
      if (token != null && deviceId.isNotEmpty) {
        try {
          await ApiClient.post('rider/helmet/pair',
              {'device_code': deviceId}, token: token);
        } catch (_) {
          // Non-fatal — user can pair later from settings
        }
      }

      if (mounted) Navigator.pushNamed(context, '/device-synced');
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Image.asset('assets/logo/logo.png',
                  height: 100, width: 100)),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'Fill in your rider details to stay safe and connected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat', fontSize: 14,
                    fontWeight: FontWeight.bold, color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Name ─────────────────────────────────────────────────────
              const SectionLabel(icon: FontAwesomeIcons.userGroup, label: 'Name'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: AppInputField(compact: true, hint: 'First Name',
                    controller: _firstNameCtrl)),
                const SizedBox(width: 10),
                Expanded(child: AppInputField(compact: true, hint: 'Middle Name',
                    controller: _middleNameCtrl)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: AppInputField(compact: true, hint: 'Last Name',
                    controller: _lastNameCtrl)),
                const SizedBox(width: 10),
                Expanded(child: AppInputField(compact: true, hint: 'Suffix',
                    controller: _suffixCtrl)),
              ]),

              const SizedBox(height: 10),

              // Date of Birth picker
              GestureDetector(
                onTap: _pickDateOfBirth,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _primaryColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(children: [
                    const FaIcon(FontAwesomeIcons.cakeCandles,
                        color: _primaryColor, size: 15),
                    const SizedBox(width: 10),
                    Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                          : 'Date of Birth',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        color: _dateOfBirth != null
                            ? Colors.black87
                            : Colors.grey[500],
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // ── Contacts ─────────────────────────────────────────────────
              const SectionLabel(icon: FontAwesomeIcons.phone, label: 'Contacts'),
              const SizedBox(height: 8),
              AppInputField(compact: true,
                hint: 'Contact Number',
                controller: _contactCtrl,
                prefixIcon: FontAwesomeIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              AppInputField(compact: true,
                hint: 'Emergency Contact Person',
                controller: _emergencyPersonCtrl,
                prefixIcon: FontAwesomeIcons.userGroup,
              ),
              const SizedBox(height: 10),
              AppInputField(compact: true,
                hint: 'Emergency Contact Number',
                controller: _emergencyNumberCtrl,
                prefixIcon: FontAwesomeIcons.phone,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // ── Address ──────────────────────────────────────────────────
              const SectionLabel(
                  icon: FontAwesomeIcons.locationDot, label: 'Address'),
              const SizedBox(height: 8),

              _loadingProvinces
                  ? const LoadingField(label: 'Loading provinces...')
                  : LocationDropdown<PsgcLocation>(
                      hint: 'Select Province',
                      value: _selectedProvince,
                      items: _provinces,
                      itemLabel: (p) => p.name,
                      onChanged: _onProvinceChanged,
                    ),

              const SizedBox(height: 10),

              _loadingMunicipalities
                  ? const LoadingField(label: 'Loading municipalities...')
                  : LocationDropdown<PsgcLocation>(
                      hint: 'Select Town/Municipality',
                      value: _selectedMunicipality,
                      items: _municipalities,
                      itemLabel: (m) => m.name,
                      onChanged: _selectedProvince != null
                          ? _onMunicipalityChanged
                          : null,
                      disabled: _selectedProvince == null,
                    ),

              const SizedBox(height: 10),

              Row(children: [
                Expanded(
                  child: _loadingBarangays
                      ? const LoadingField(label: 'Loading barangays...')
                      : LocationDropdown<PsgcLocation>(
                          hint: 'Select Barangay',
                          value: _selectedBarangay,
                          items: _barangays,
                          itemLabel: (b) => b.name,
                          onChanged: _selectedMunicipality != null
                              ? (v) => setState(() => _selectedBarangay = v)
                              : null,
                          disabled: _selectedMunicipality == null,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppInputField(compact: true,
                    hint: 'Device ID',
                    controller: _deviceIdCtrl,
                    prefixIcon: FontAwesomeIcons.microchip,
                  ),
                ),
              ]),

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
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'Montserrat', fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              const Center(
                child: Text(
                  'Save and secure your profile.',
                  style: TextStyle(
                    fontFamily: 'Montserrat', fontSize: 13, color: Colors.black54,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
