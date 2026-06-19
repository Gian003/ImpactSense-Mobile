import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/core/services/psgc_service.dart';
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

  // Location state
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
      final municipalities =
          await PsgcService.fetchMunicipalities(province.code);
      if (mounted) {
        setState(() {
          _municipalities = municipalities;
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
      final barangays = await PsgcService.fetchBarangays(municipality.code);
      if (mounted) {
        setState(() {
          _barangays = barangays;
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
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child:
                    Image.asset('assets/logo/logo.png', height: 100, width: 100),
              ),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'Fill in your rider details to stay safe and connected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Name
              const SectionLabel(
                  icon: FontAwesomeIcons.userGroup, label: 'Name'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: AppInputField(compact: true,hint: 'First Name')),
                  const SizedBox(width: 10),
                  Expanded(child: AppInputField(compact: true,hint: 'Middle Name')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: AppInputField(compact: true,hint: 'Last Name')),
                  const SizedBox(width: 10),
                  Expanded(child: AppInputField(compact: true,hint: 'Suffix')),
                ],
              ),

              const SizedBox(height: 16),

              // Contacts
              const SectionLabel(
                  icon: FontAwesomeIcons.phone, label: 'Contacts'),
              const SizedBox(height: 8),
              AppInputField(compact: true,
                hint: 'Contact Number',
                prefixIcon: FontAwesomeIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              AppInputField(compact: true,
                hint: 'Emergency Contact Person',
                prefixIcon: FontAwesomeIcons.userGroup,
              ),
              const SizedBox(height: 10),
              AppInputField(compact: true,
                hint: 'Emergency Contact Number',
                prefixIcon: FontAwesomeIcons.phone,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Address
              const SectionLabel(
                  icon: FontAwesomeIcons.locationDot, label: 'Address'),
              const SizedBox(height: 8),

              // Province
              _loadingProvinces
                  ? LoadingField(label: 'Loading provinces...')
                  : LocationDropdown<PsgcLocation>(
                      hint: 'Select Province',
                      value: _selectedProvince,
                      items: _provinces,
                      itemLabel: (p) => p.name,
                      onChanged: _onProvinceChanged,
                    ),

              const SizedBox(height: 10),

              // Municipality
              _loadingMunicipalities
                  ? LoadingField(label: 'Loading municipalities...')
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

              // Barangay + Device ID
              Row(
                children: [
                  Expanded(
                    child: _loadingBarangays
                        ? LoadingField(label: 'Loading barangays...')
                        : LocationDropdown<PsgcLocation>(
                            hint: 'Select Barangay',
                            value: _selectedBarangay,
                            items: _barangays,
                            itemLabel: (b) => b.name,
                            onChanged: _selectedMunicipality != null
                                ? (v) =>
                                    setState(() => _selectedBarangay = v)
                                : null,
                            disabled: _selectedMunicipality == null,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppInputField(compact: true,
                      hint: 'Device ID',
                      prefixIcon: FontAwesomeIcons.microchip,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/device-synced'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }
}
