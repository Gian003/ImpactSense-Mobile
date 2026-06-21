import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:impactsense/core/services/api_client.dart';
import 'package:impactsense/core/services/realtime_service.dart';
import 'package:impactsense/core/services/session_service.dart';

// ── Step model ────────────────────────────────────────────────────────────────

enum _Status { idle, running, pass, fail }

class _Step {
  final String label;
  final String description;
  _Status status;
  String? detail;
  _Step({required this.label, required this.description}) : status = _Status.idle;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SystemTestScreen extends StatefulWidget {
  const SystemTestScreen({super.key});

  @override
  State<SystemTestScreen> createState() => _SystemTestScreenState();
}

class _SystemTestScreenState extends State<SystemTestScreen> {
  static const _primary   = Color(0xFF1A6B78);
  static const _bg        = Color(0xFFF0F2F4);

  // Urdaneta City, Pangasinan — default map centre
  static const _defaultCenter = LatLng(15.9754, 120.5697);

  // ── Test state ──────────────────────────────────────────────────────────────
  bool  _running            = false;
  int?  _createdIncidentId;
  bool  _pusherEventReceived = false;
  final _realtime = RealtimeService();

  // ── Map state ───────────────────────────────────────────────────────────────
  GoogleMapController? _mapCtrl;
  final Set<Marker>   _markers  = {};
  LatLng?             _crashPos;   // set in step 4

  // ── IoT field ───────────────────────────────────────────────────────────────
  final _deviceCodeCtrl = TextEditingController(text: 'ITK-BLK4-GRP5-MDL1');

  // ── Steps ───────────────────────────────────────────────────────────────────
  late final List<_Step> _steps = [
    _Step(label: 'Step 1', description: 'API reachable (GET /up)'),
    _Step(label: 'Step 2', description: 'Rider authenticated (Sanctum token valid)'),
    _Step(label: 'Step 3', description: 'GPS location obtained → pinned on map'),
    _Step(label: 'Step 4', description: 'Crash reported → POST /api/rider/incidents → crash pin dropped'),
    _Step(label: 'Step 5', description: 'Incident saved in DB (id returned)'),
    _Step(label: 'Step 6', description: 'Pusher connected to incidents channel'),
    _Step(label: 'Step 7', description: 'Simulate dispatch → PATCH status → patrol pin appears'),
    _Step(label: 'Step 8', description: 'IncidentStatusUpdated event received via Pusher → pin turns orange'),
  ];

  @override
  void dispose() {
    _deviceCodeCtrl.dispose();
    _mapCtrl?.dispose();
    _realtime.disconnect();
    super.dispose();
  }

  // ── Run all steps ────────────────────────────────────────────────────────────

  Future<void> _runAllSteps() async {
    if (_running) return;
    setState(() {
      _running             = true;
      _pusherEventReceived = false;
      _createdIncidentId   = null;
      _markers.clear();
      _crashPos = null;
      for (final s in _steps) { s.status = _Status.idle; s.detail = null; }
    });

    await _step1ApiHealth();
    await _step2AuthCheck();
    final position = await _step3Gps();
    await _step4ReportCrash(position);
    _step5CheckIncidentId();
    await _step6Pusher();
    await _step7SimulateDispatch();
    await _step8PusherEvent();

    setState(() => _running = false);
  }

  // ── Steps ────────────────────────────────────────────────────────────────────

  Future<void> _step1ApiHealth() async {
    _setRunning(0);
    try {
      final res = await ApiClient.get('health');
      _setResult(0, res['status'] == 'up', 'Server responded');
    } catch (e) {
      _setResult(0, false, e.toString());
    }
  }

  Future<void> _step2AuthCheck() async {
    _setRunning(1);
    final token = await SessionService.getToken();
    if (token == null) { _setResult(1, false, 'No token — log in first'); return; }
    try {
      final res = await ApiClient.get('rider/profile', token: token);
      _setResult(1, res['success'] == true,
          res['success'] == true
              ? 'Logged in as ${res['data']?['full_name']}'
              : 'Token rejected');
    } catch (e) {
      _setResult(1, false, e.toString());
    }
  }

  Future<Position?> _step3Gps() async {
    _setRunning(2);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      final latLng = LatLng(pos.latitude, pos.longitude);

      // Drop blue rider pin on map and fly camera there
      _addMarker(
        id:       'rider',
        position: latLng,
        title:    'Your Location',
        hue:      BitmapDescriptor.hueAzure,
      );
      _animateCamera(latLng, zoom: 15);

      _setResult(2, true,
          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
      return pos;
    } catch (e) {
      _setResult(2, false, e.toString());
      return null;
    }
  }

  Future<void> _step4ReportCrash(Position? pos) async {
    _setRunning(3);
    final token = await SessionService.getToken();
    if (token == null) { _setResult(3, false, 'Not logged in'); return; }

    final lat = pos?.latitude  ?? _defaultCenter.latitude;
    final lng = pos?.longitude ?? _defaultCenter.longitude;
    final latLng = LatLng(lat, lng);

    try {
      final res = await ApiClient.post('rider/incidents', {
        'type'     : 'collision',
        'latitude' : lat,
        'longitude': lng,
        'address'  : 'Simulated crash — System Test',
        'severity' : 'high',
      }, token: token);

      final ok = res['success'] == true;
      if (ok) {
        _createdIncidentId = res['data']?['id'] as int?;
        _crashPos = latLng;

        // Drop red crash pin and zoom in
        _addMarker(
          id:       'crash',
          position: latLng,
          title:    'Crash Detected',
          snippet:  'Incident #$_createdIncidentId',
          hue:      BitmapDescriptor.hueRed,
        );
        _animateCamera(latLng, zoom: 16);
      }

      _setResult(3, ok,
          ok ? 'HTTP 201 — Incident #$_createdIncidentId' : res['message']);
    } catch (e) {
      _setResult(3, false, e.toString());
    }
  }

  void _step5CheckIncidentId() {
    _setRunning(4);
    final ok = _createdIncidentId != null;
    _setResult(4, ok,
        ok ? 'Incident ID: $_createdIncidentId stored in DB' : 'No ID — check step 4');
  }

  Future<void> _step6Pusher() async {
    _setRunning(5);
    try {
      await _realtime.connect().timeout(const Duration(seconds: 8));
      await _realtime.listenForIncidents(
        (_) {},
        onStatusUpdate: (_) => setState(() => _pusherEventReceived = true),
      );
      _setResult(5, true, 'Connected to Pusher "incidents" channel');
    } catch (e) {
      _setResult(5, false, 'Pusher: $e — check PUSHER_APP_KEY in .env');
    }
  }

  Future<void> _step7SimulateDispatch() async {
    _setRunning(6);
    if (_createdIncidentId == null) {
      _setResult(6, false, 'No incident to dispatch — step 4 failed');
      return;
    }

    final token = await SessionService.getToken();
    if (token == null) { _setResult(6, false, 'Not logged in'); return; }

    try {
      final res = await ApiClient.patch(
        'patrol/incidents/$_createdIncidentId/status',
        {'status': 'false_alarm', 'notes': 'System test — auto-resolved'},
        token: token,
      );
      final ok = res['success'] == true;

      if (ok && _crashPos != null) {
        // Simulated patrol unit appears ~1 km south-east of the crash
        final patrolPos = LatLng(
          _crashPos!.latitude  - 0.008,
          _crashPos!.longitude + 0.010,
        );
        _addMarker(
          id:       'patrol',
          position: patrolPos,
          title:    'Patrol Dispatched',
          snippet:  'Responding to Incident #$_createdIncidentId',
          hue:      BitmapDescriptor.hueGreen,
        );
        // Zoom out to show both crash and patrol
        _animateCameraBounds(
          bounds: LatLngBounds(
            southwest: LatLng(
              patrolPos.latitude  < _crashPos!.latitude  ? patrolPos.latitude  : _crashPos!.latitude,
              patrolPos.longitude < _crashPos!.longitude ? patrolPos.longitude : _crashPos!.longitude,
            ),
            northeast: LatLng(
              patrolPos.latitude  > _crashPos!.latitude  ? patrolPos.latitude  : _crashPos!.latitude,
              patrolPos.longitude > _crashPos!.longitude ? patrolPos.longitude : _crashPos!.longitude,
            ),
          ),
          padding: 80,
        );
      }

      _setResult(6, ok,
          ok ? 'Status → false_alarm — patrol pin on map' : res['message'] ?? 'Error');
    } catch (e) {
      _setResult(6, false, e.toString());
    }
  }

  Future<void> _step8PusherEvent() async {
    _setRunning(7);
    final completer = Completer<bool>();
    Timer(const Duration(seconds: 3), () {
      if (!completer.isCompleted) completer.complete(_pusherEventReceived);
    });

    final received = await completer.future;

    if (received && _crashPos != null) {
      // Crash pin turns orange — status updated via Pusher
      _addMarker(
        id:       'crash',
        position: _crashPos!,
        title:    'Status Updated',
        snippet:  'Pusher event received ✓',
        hue:      BitmapDescriptor.hueOrange,
      );
    }

    _setResult(7, received,
        received
            ? 'IncidentStatusUpdated received via Pusher ✓'
            : 'No event in 3 s — check Pusher config');
  }

  // ── IoT direct simulation ─────────────────────────────────────────────────

  Future<void> _simulateIoTDevice() async {
    final code = _deviceCodeCtrl.text.trim();
    if (code.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending crash from IoT device…')),
    );

    const iotPos = LatLng(15.9754, 120.5697);

    try {
      final res = await ApiClient.post('device/incident', {
        'device_code': code,
        'latitude'   : iotPos.latitude,
        'longitude'  : iotPos.longitude,
        'type'       : 'collision',
        'severity'   : 'critical',
        'address'    : 'IoT simulation — Urdaneta Bypass Road',
      });

      final ok = res['success'] == true;

      if (ok) {
        // Show IoT crash pin on the map
        _addMarker(
          id:       'iot_crash',
          position: iotPos,
          title:    'IoT Crash',
          snippet:  'Device: $code',
          hue:      BitmapDescriptor.hueViolet,
        );
        _animateCamera(iotPos, zoom: 15);
      }

      if (!mounted) return;
      _showSnack(ok,
          ok
              ? 'IoT reported — ID: ${res['data']?['incident_id']}'
              : res['message'] ?? 'Failed');
    } catch (e) {
      if (!mounted) return;
      _showSnack(false, e.toString());
    }
  }

  // ── Map helpers ───────────────────────────────────────────────────────────

  void _addMarker({
    required String id,
    required LatLng position,
    required String title,
    String? snippet,
    required double hue,
  }) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(Marker(
        markerId: MarkerId(id),
        position: position,
        infoWindow: InfoWindow(title: title, snippet: snippet),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      ));
    });
  }

  void _animateCamera(LatLng target, {double zoom = 15}) {
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  void _animateCameraBounds({required LatLngBounds bounds, double padding = 60}) {
    _mapCtrl?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  // ── Misc helpers ──────────────────────────────────────────────────────────

  void _showSnack(bool ok, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Montserrat')),
      backgroundColor: ok ? Colors.green[700] : Colors.red[700],
      duration: const Duration(seconds: 4),
    ));
  }

  void _setRunning(int i) => setState(() => _steps[i].status = _Status.running);

  void _setResult(int i, bool ok, String detail) => setState(() {
    _steps[i].status = ok ? _Status.pass : _Status.fail;
    _steps[i].detail = detail;
  });

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final passCount = _steps.where((s) => s.status == _Status.pass).length;
    final failCount = _steps.where((s) => s.status == _Status.fail).length;
    final allDone   = !_running && passCount + failCount == _steps.length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('System Test',
            style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [

          // ── Live map panel ────────────────────────────────────────────────
          _MapPanel(
            markers:      _markers,
            onMapCreated: (ctrl) => _mapCtrl = ctrl,
          ),

          // ── Map legend strip ──────────────────────────────────────────────
          _MapLegendStrip(hasData: _markers.isNotEmpty),

          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // Summary banner
                if (allDone)
                  _SummaryBanner(passCount: passCount, failCount: failCount),

                // Step list
                const _SectionLabel(text: 'Crash-to-Dispatch Chain'),
                const SizedBox(height: 8),
                ...List.generate(_steps.length, (i) => _StepRow(step: _steps[i])),

                const SizedBox(height: 16),

                // Run button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _running ? null : _runAllSteps,
                    icon: _running
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const FaIcon(FontAwesomeIcons.play, size: 16),
                    label: Text(
                      _running ? 'Running…' : 'Run Full Chain Test',
                      style: const TextStyle(
                          fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // IoT simulation
                const _SectionLabel(text: 'Simulate IoT Device (no login required)'),
                const SizedBox(height: 8),
                _IoTPanel(
                  controller: _deviceCodeCtrl,
                  onSimulate: _simulateIoTDevice,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map panel (fixed height) ──────────────────────────────────────────────────

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.markers, required this.onMapCreated});

  final Set<Marker>                       markers;
  final void Function(GoogleMapController) onMapCreated;

  static const _defaultCenter = LatLng(15.9754, 120.5697);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: 13,
            ),
            onMapCreated: onMapCreated,
            markers:              markers,
            myLocationEnabled:    true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled:  false,
            mapToolbarEnabled:    false,
          ),

          // "Live" badge
          Positioned(
            top: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                const Text('LIVE', style: TextStyle(
                  fontFamily: 'Montserrat', fontSize: 11,
                  color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1,
                )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map legend strip ──────────────────────────────────────────────────────────

class _MapLegendStrip extends StatelessWidget {
  const _MapLegendStrip({required this.hasData});
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _Dot(color: Colors.blue[600]!,   label: 'You'),
          const SizedBox(width: 12),
          _Dot(color: Colors.red,           label: 'Crash'),
          const SizedBox(width: 12),
          _Dot(color: Colors.green[700]!,  label: 'Patrol'),
          const SizedBox(width: 12),
          _Dot(color: Colors.orange[700]!, label: 'Status updated'),
          const SizedBox(width: 12),
          _Dot(color: Colors.purple,       label: 'IoT device'),
          if (!hasData) ...[
            const SizedBox(width: 16),
            Text('Run test to see pins',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, color: Colors.grey[500])),
          ],
        ]),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 10, color: Colors.black54)),
  ]);
}

// ── Summary banner ────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.passCount, required this.failCount});
  final int passCount, failCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: failCount == 0 ? Colors.green[700] : Colors.red[700],
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      FaIcon(
        failCount == 0 ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circleXmark,
        color: Colors.white, size: 20,
      ),
      const SizedBox(width: 10),
      Text(
        failCount == 0
            ? 'All $passCount steps passed — chain is healthy'
            : '$passCount passed, $failCount failed',
        style: const TextStyle(
            fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ]),
  );
}

// ── IoT panel ─────────────────────────────────────────────────────────────────

class _IoTPanel extends StatelessWidget {
  const _IoTPanel({required this.controller, required this.onSimulate});
  final TextEditingController controller;
  final VoidCallback onSimulate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1A6B78).withValues(alpha: 0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(
        'Sends POST /api/device/incident using device_code — '
        'mimics the physical helmet. A purple pin will appear on the map.',
        style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: Colors.black54),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Device Code',
          hintText: 'ITK-BLK4-GRP5-MDL1',
          labelStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: FaIcon(FontAwesomeIcons.microchip, size: 16, color: Color(0xFF1A6B78)),
          ),
        ),
        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onSimulate,
          icon: const FaIcon(FontAwesomeIcons.bolt, size: 14),
          label: const Text('Simulate Crash from Helmet',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ),
    ]),
  );
}

// ── Step row ──────────────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (step.status) {
      _Status.idle    => (FontAwesomeIcons.circle,      Colors.grey),
      _Status.running => (FontAwesomeIcons.spinner,     const Color(0xFF1A6B78)),
      _Status.pass    => (FontAwesomeIcons.circleCheck, Colors.green[700]!),
      _Status.fail    => (FontAwesomeIcons.circleXmark, Colors.red[700]!),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: switch (step.status) {
          _Status.pass => Colors.green.withValues(alpha: 0.4),
          _Status.fail => Colors.red.withValues(alpha: 0.4),
          _            => Colors.grey.withValues(alpha: 0.2),
        }),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        step.status == _Status.running
            ? SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color))
            : FaIcon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${step.label}  •  ${step.description}',
                style: const TextStyle(
                    fontFamily: 'Montserrat', fontSize: 13,
                    fontWeight: FontWeight.w600, color: Colors.black87)),
            if (step.detail != null) ...[
              const SizedBox(height: 3),
              Text(step.detail!,
                  style: TextStyle(
                      fontFamily: 'Montserrat', fontSize: 11,
                      color: step.status == _Status.fail
                          ? Colors.red[700]
                          : Colors.grey[600])),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontFamily: 'Montserrat', fontSize: 13,
          fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.4));
}
