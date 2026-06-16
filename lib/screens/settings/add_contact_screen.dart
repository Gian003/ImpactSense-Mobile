import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/core/services/psgc_service.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  // PSGC state
  List<PsgcLocation> _provinces = [];
  List<PsgcLocation> _municipalities = [];
  List<PsgcLocation> _barangays = [];

  PsgcLocation? _selectedProvince;
  PsgcLocation? _selectedMunicipality;
  PsgcLocation? _selectedBarangay;

  bool _loadingProvinces = true;
  bool _loadingMunicipalities = false;
  bool _loadingBarangays = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await PsgcService.fetchProvinces();
      if (mounted) {
        setState(() {
          _provinces = provinces;
          _loadingProvinces = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _onProvinceChanged(PsgcLocation? province) async {
    setState(() {
      _selectedProvince = province;
      _selectedMunicipality = null;
      _selectedBarangay = null;
      _municipalities = [];
      _barangays = [];
      _loadingMunicipalities = province != null;
    });
    if (province == null) return;
    try {
      final list = await PsgcService.fetchMunicipalities(province.code);
      if (mounted) {
        setState(() {
          _municipalities = list;
          _loadingMunicipalities = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMunicipalities = false);
    }
  }

  Future<void> _onMunicipalityChanged(PsgcLocation? municipality) async {
    setState(() {
      _selectedMunicipality = municipality;
      _selectedBarangay = null;
      _barangays = [];
      _loadingBarangays = municipality != null;
    });
    if (municipality == null) return;
    try {
      final list = await PsgcService.fetchBarangays(municipality.code);
      if (mounted) {
        setState(() {
          _barangays = list;
          _loadingBarangays = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBarangays = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back button row
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
                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/logo/logo.png',
                        height: 90,
                        width: 90,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    const Center(
                      child: Text(
                        'Fill in your rider details to stay safe and connected',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Name
                    const _SectionLabel(
                        icon: FontAwesomeIcons.userGroup, label: 'Name'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _InputField(hint: 'First Name')),
                        const SizedBox(width: 10),
                        Expanded(child: _InputField(hint: 'Middle Name')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _InputField(hint: 'Last Name')),
                        const SizedBox(width: 10),
                        Expanded(child: _InputField(hint: 'Suffix')),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Contacts
                    const _SectionLabel(
                        icon: FontAwesomeIcons.phone, label: 'Contacts'),
                    const SizedBox(height: 8),
                    _InputField(
                      hint: 'Contact Number',
                      prefixIcon: FontAwesomeIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    _InputField(
                      hint: 'Emergency Contact Person',
                      prefixIcon: FontAwesomeIcons.userGroup,
                    ),
                    const SizedBox(height: 10),
                    _InputField(
                      hint: 'Emergency Contact Number',
                      prefixIcon: FontAwesomeIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    // Address
                    const _SectionLabel(
                        icon: FontAwesomeIcons.locationDot,
                        label: 'Address'),
                    const SizedBox(height: 8),

                    // Province
                    _loadingProvinces
                        ? _LoadingField(label: 'Loading provinces...')
                        : _LocationDropdown<PsgcLocation>(
                            hint: 'Select Province',
                            value: _selectedProvince,
                            items: _provinces,
                            itemLabel: (p) => p.name,
                            onChanged: _onProvinceChanged,
                          ),

                    const SizedBox(height: 10),

                    // Municipality
                    _loadingMunicipalities
                        ? _LoadingField(label: 'Loading municipalities...')
                        : _LocationDropdown<PsgcLocation>(
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

                    // Barangay + Device ID
                    Row(
                      children: [
                        Expanded(
                          child: _loadingBarangays
                              ? _LoadingField(label: 'Loading barangays...')
                              : _LocationDropdown<PsgcLocation>(
                                  hint: 'Select Barangay',
                                  value: _selectedBarangay,
                                  items: _barangays,
                                  itemLabel: (b) => b.name,
                                  onChanged: _selectedMunicipality != null
                                      ? (v) => setState(
                                          () => _selectedBarangay = v)
                                      : null,
                                  disabled: _selectedMunicipality == null,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InputField(
                            hint: 'Device ID',
                            prefixIcon: FontAwesomeIcons.microchip,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _primaryColor,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
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
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          color: Colors.black54,
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

// ── Reusable widgets (mirrors personal_information_screen) ────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final FaIconData icon;
  final String label;

  static const _primaryColor = Color(0xFF1A6B78);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 6),
        FaIcon(icon, color: _primaryColor, size: 16),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField(
      {required this.hint, this.prefixIcon, this.keyboardType});

  final String hint;
  final FaIconData? prefixIcon;
  final TextInputType? keyboardType;

  static const _primaryColor = Color(0xFF1A6B78);

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Montserrat', fontSize: 13, color: Colors.grey[500]),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: FaIcon(prefixIcon, color: _primaryColor, size: 16),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _primaryColor.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _primaryColor.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

class _LocationDropdown<T> extends StatelessWidget {
  const _LocationDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.disabled = false,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;
  final bool disabled;

  static const _primaryColor = Color(0xFF1A6B78);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      hint: Text(
        hint,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
          color: disabled ? Colors.grey[400] : Colors.grey[500],
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(itemLabel(e),
                    style: const TextStyle(
                        fontFamily: 'Montserrat', fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: disabled ? null : onChanged,
      isExpanded: true,
      icon: FaIcon(FontAwesomeIcons.chevronDown,
          size: 14,
          color: disabled ? Colors.grey[400] : _primaryColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: disabled ? Colors.grey[100] : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _primaryColor.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _primaryColor.withValues(alpha: 0.4)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

class _LoadingField extends StatelessWidget {
  const _LoadingField({required this.label});

  final String label;

  static const _primaryColor = Color(0xFF1A6B78);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _primaryColor),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: Colors.grey[500])),
        ],
      ),
    );
  }
}
