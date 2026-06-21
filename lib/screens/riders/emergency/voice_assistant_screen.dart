import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:impactsense/core/services/api_client.dart';
import 'package:impactsense/core/services/session_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  static const _primaryColor = Color(0xFF1A6B78);

  bool _isOn      = false;
  bool _sending   = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _turnOn() {
    setState(() => _isOn = true);
    _waveController.repeat(reverse: true);
  }

  void _stop() {
    setState(() => _isOn = false);
    _waveController.stop();
    _waveController.reset();
  }

  Future<void> _sendToAllContacts() async {
    if (_sending) return;
    setState(() => _sending = true);

    double lat = 15.9754, lng = 120.5697;
    String locationLabel = 'Urdaneta City, Pangasinan';
    int contactCount = 0;

    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high));
        lat = pos.latitude;
        lng = pos.longitude;
        locationLabel =
            '${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E';
      }
    } catch (_) {}

    try {
      final token = await SessionService.getToken();
      if (token != null) {
        final res = await ApiClient.post('rider/incidents', {
          'type'     : 'voice_alert',
          'latitude' : lat,
          'longitude': lng,
          'severity' : 'high',
        }, token: token);

        if (res['success'] == true) {
          final contacts = await ApiClient.get(
              'rider/emergency-contacts', token: token);
          if (contacts['success'] == true) {
            contactCount = ((contacts['data'] as List?) ?? []).length;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _sending = false);

    Navigator.pushReplacementNamed(context, '/emergency-sent', arguments: {
      'location'    : locationLabel,
      'contactCount': contactCount,
    });
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
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    size: 22,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),

            // Title badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.microphone,
                        color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Voice Assistant',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Logo
            Center(
              child: Image.asset(
                'assets/logo/logo.png',
                height: 110,
                width: 110,
              ),
            ),

            const SizedBox(height: 48),

            // Waveform + mic
            Center(
              child: SizedBox(
                height: 64,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (_, __) => _Waveform(
                    progress: _waveController.value,
                    active: _isOn,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // on / stop toggles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _ToggleButton(
                    label: 'on',
                    color: Colors.green,
                    active: _isOn,
                    onTap: _turnOn,
                  ),
                  const Spacer(),
                  _ToggleButton(
                    label: 'stop',
                    color: const Color(0xFF333333),
                    active: !_isOn,
                    onTap: _stop,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Send Voice All Contacts button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _sendToAllContacts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.microphone, size: 18),
                  label: const Text(
                    'Send Voice All Contacts',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
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

// ── Waveform widget ───────────────────────────────────────────────────────────

class _Waveform extends StatelessWidget {
  const _Waveform({required this.progress, required this.active});

  final double progress;
  final bool active;

  static const _barCount = 20;
  static const _barWidth = 3.0;
  static const _gap = 4.0;
  static const _maxHeight = 48.0;
  static const _minHeight = 6.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left bars
        ...List.generate(_barCount, (i) {
          final phase = i / _barCount;
          final height = active
              ? _minHeight +
                  (_maxHeight - _minHeight) *
                      (0.5 + 0.5 * sin((progress + phase) * 2 * pi))
              : _minHeight + (_maxHeight - _minHeight) * 0.15;
          return _Bar(height: height);
        }),

        // Mic icon
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: FaIcon(
            FontAwesomeIcons.microphone,
            size: 28,
            color: Colors.black87,
          ),
        ),

        // Right bars (mirror)
        ...List.generate(_barCount, (i) {
          final phase = (_barCount - i) / _barCount;
          final height = active
              ? _minHeight +
                  (_maxHeight - _minHeight) *
                      (0.5 + 0.5 * sin((progress + phase) * 2 * pi))
              : _minHeight + (_maxHeight - _minHeight) * 0.15;
          return _Bar(height: height);
        }),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: _Waveform._barWidth,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: _Waveform._gap / 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ── Toggle button ─────────────────────────────────────────────────────────────

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
