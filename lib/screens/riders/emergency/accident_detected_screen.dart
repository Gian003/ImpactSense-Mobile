import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:impactsense/core/services/api_client.dart';
import 'package:impactsense/core/services/session_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AccidentDetectedScreen extends StatefulWidget {
  const AccidentDetectedScreen({super.key, this.alreadyReported = false});

  /// True when this screen was opened automatically because the IoT device
  /// already reported the crash to the backend (via FCM push) - in that case
  /// the countdown must NOT post a second incident on expiry.
  final bool alreadyReported;

  @override
  State<AccidentDetectedScreen> createState() =>
      _AccidentDetectedScreenState();
}

class _AccidentDetectedScreenState extends State<AccidentDetectedScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  int    _remainingSeconds = 59;
  Timer? _timer;
  bool   _reporting        = false;

  // GPS position captured on mount
  double? _lat;
  double? _lng;
  String  _locationLabel = 'Your current location';

  @override
  void initState() {
    super.initState();
    _captureLocation();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        // Fall back to Urdaneta City
        _lat = 15.9754;
        _lng = 120.5697;
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      _lat = pos.latitude;
      _lng = pos.longitude;
      _locationLabel =
          '${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E';
    } catch (_) {
      _lat = 15.9754;
      _lng = 120.5697;
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 0) {
        t.cancel();
        _onTimerExpired();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _onTimerExpired() => _report(autoTriggered: true);

  Future<void> _report({bool autoTriggered = false}) async {
    if (_reporting) return;
    _timer?.cancel();
    setState(() => _reporting = true);

    int contactCount = 0;
    final token = await SessionService.getToken();

    if (token != null) {
      // Skip re-reporting if the IoT device already reported this crash -
      // otherwise this would create a second, duplicate incident.
      if (!widget.alreadyReported) {
        try {
          await ApiClient.post('rider/incidents', {
            'type'     : 'collision',
            'latitude' : _lat  ?? 15.9754,
            'longitude': _lng  ?? 120.5697,
            'severity' : 'critical',
          }, token: token);
        } catch (_) {
          // Non-fatal — proceed to call 911 anyway
        }
      }

      try {
        final contacts = await ApiClient.get(
            'rider/emergency-contacts', token: token);
        if (contacts['success'] == true) {
          final list = contacts['data'] as List? ?? [];
          contactCount = list.length;
        }
      } catch (_) {}
    }

    // 2. Call 911
    final uri = Uri(scheme: 'tel', path: '911');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }

    // 3. Navigate to confirmation
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/emergency-sent',
        arguments: {
          'location'     : _locationLabel,
          'contactCount' : contactCount,
        },
      );
    }
  }

  void _ignore() {
    _timer?.cancel();
    Navigator.pop(context);
  }

  String get _display {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '00:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    child: const Icon(Icons.chevron_left,
                        size: 22, color: Colors.black54),
                  ),
                ),
              ),

              // Red banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accident detected',
                        style: TextStyle(
                          fontFamily: 'Montserrat', fontSize: 18,
                          fontWeight: FontWeight.bold, color: Colors.white,
                        ),
                      ),
                      FaIcon(FontAwesomeIcons.triangleExclamation,
                          color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Countdown circle
              Center(
                child: Container(
                  width: 170, height: 170,
                  decoration: const BoxDecoration(
                      color: _primaryColor, shape: BoxShape.circle),
                  child: Center(
                    child: _reporting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _display,
                            style: const TextStyle(
                              fontFamily: 'Montserrat', fontSize: 26,
                              fontWeight: FontWeight.bold, color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Center(
                child: Text(
                  'An alert will be sent to your\nemergency contacts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Montserrat',
                      fontSize: 14, color: Colors.black87),
                ),
              ),

              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Call Emergency Contact
                    GestureDetector(
                      onTap: _reporting ? null : () => _report(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: _primaryColor.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.phone,
                                color: Colors.green, size: 18),
                            SizedBox(width: 10),
                            Text('Call Emergency Contact',
                                style: TextStyle(
                                  fontFamily: 'Montserrat', fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                )),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // IGNORE
                    GestureDetector(
                      onTap: _reporting ? null : _ignore,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.xmark,
                                color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Text('IGNORE',
                                style: TextStyle(
                                  fontFamily: 'Montserrat', fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, letterSpacing: 1,
                                )),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.alreadyReported
                            ? 'Your device already reported this crash. Calling 911 and confirming with emergency contacts in (1) minute if no action is taken.'
                            : 'Automatically calling and location sent to emergency contacts in (1) minute if no action is taken.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Montserrat',
                            fontSize: 13, color: Colors.black87),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
