import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:impactsense/core/models/patrol_incident.dart';
import 'package:impactsense/core/services/api_client.dart';
import 'package:impactsense/core/services/auth_service.dart';
import 'package:impactsense/core/services/patrol_service.dart';
import 'package:impactsense/core/services/realtime_service.dart';
import 'package:impactsense/core/services/session_service.dart';
import 'package:impactsense/screens/maintenance/system_test_screen.dart';

// ── Root screen ───────────────────────────────────────────────────────────────

class PatrolHomeScreen extends StatefulWidget {
  const PatrolHomeScreen({super.key});

  @override
  State<PatrolHomeScreen> createState() => _PatrolHomeScreenState();
}

class _PatrolHomeScreenState extends State<PatrolHomeScreen> {
  static const _primaryColor = Color(0xFF1A6B78);
  static const _navBg = Color(0xFF0D3D47);

  int _tab = 1; // start on map tab
  String  _patrollerName = 'Patroller';
  String  _patrollerEmail = '';
  Timer?  _locationTimer;
  final   _realtime = RealtimeService();

  // Live incidents (loaded from API + updated via Pusher)
  List<Map<String, dynamic>> _incidents = [];

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadIncidents();
    _startLocationUpdates();
    _connectRealtime();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _realtime.disconnect();
    super.dispose();
  }

  Future<void> _loadName() async {
    final name  = await SessionService.getName();
    final email = await SessionService.getEmail();
    if (!mounted) return;
    setState(() {
      if (name  != null) _patrollerName  = name;
      if (email != null) _patrollerEmail = email;
    });
  }

  Future<void> _loadIncidents() async {
    try {
      final token = await SessionService.getToken();
      if (token == null) return;
      final res = await ApiClient.get('patrol/incidents', token: token);
      if (res['success'] == true && mounted) {
        final list = res['data'] as List<dynamic>? ?? [];
        setState(() {
          _incidents = list.map((e) =>
              Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {
      // Keep empty list on error
    }
  }

  Future<void> _connectRealtime() async {
    await _realtime.connect();
    // Each patrol unit listens on its own private channel: patrol.{id}
    final token = await SessionService.getToken();
    if (token == null) return;
    // Retrieve patrol unit ID from backend profile if needed; for now we derive
    // it from the session. The channel name uses the numeric ID stored by the
    // login response.
    final prefs = await _getPatrolUnitId();
    if (prefs != null) {
      await _realtime.listenForDispatch(prefs, _onDispatchReceived);
    }
  }

  Future<int?> _getPatrolUnitId() async {
    return SessionService.getUserId();
  }

  void _onDispatchReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    // Add to local incidents list so notification tab updates immediately
    setState(() => _incidents.insert(0, data));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'DISPATCH: ${data['type']} at ${data['address'] ?? 'unknown location'}',
          style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _pushLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pushLocation());
  }

  Future<void> _pushLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await PatrolService.updateLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (_) {}
  }

  // In production this arrives via FCM / WebSocket from the admin backend
  final _incident = const PatrolIncident(
    type: 'Traffic Accident',
    address: 'Brgy. Cabuloan, Urdaneta City, Pangasinan',
    incidentCoordinates: LatLng(16.015, 120.574),
    destinationCoordinates: LatLng(15.9754, 120.5697),
    reportedAt: 'April 20, 10:30 AM',
    reportedBy: 'Vladimir V. Lalas',
  );

  void _viewDetails() {
    Navigator.pushNamed(
      context,
      '/patrol-accident-map',
      arguments: _incident,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F4),
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _NotificationsTab(
              incident:    _incident,
              incidents:   _incidents,
              primaryColor: _primaryColor,
              onViewDetails: _viewDetails,
              onBack: () => setState(() => _tab = 1),
            ),
            _MapTab(
              incident: _incident,
              primaryColor: _primaryColor,
              patrollerName: _patrollerName,
              onViewDetails: _viewDetails,
            ),
            _PatrolSettingsTab(
              primaryColor: _primaryColor,
              patrollerName: _patrollerName,
              patrollerEmail: _patrollerEmail,
              onBack: () => setState(() => _tab = 1),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PatrolBottomNav(
        currentIndex: _tab,
        navBg: _navBg,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _PatrolHeader extends StatelessWidget {
  const _PatrolHeader({required this.primaryColor, required this.patrollerName});

  final Color primaryColor;
  final String patrollerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Image.asset(
            'assets/logo/pnp-urdaneta.png',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const FaIcon(FontAwesomeIcons.shieldHalved, color: Colors.red, size: 22),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning,',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  patrollerName,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'PNP Highway Patrol Group',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.bell,
                    color: Colors.white,
                    size: 22,
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab 0 — Notifications list ────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({
    required this.incident,
    required this.incidents,
    required this.primaryColor,
    required this.onViewDetails,
    required this.onBack,
  });

  final PatrolIncident                   incident;
  final List<Map<String, dynamic>>       incidents;
  final Color                            primaryColor;
  final VoidCallback                     onViewDetails;
  final VoidCallback                     onBack;

  static const _cardBg = Color(0xFFCCE4EA);
  static const _cardDark = Color(0xFF163848);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F2F4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // ── Cards ─────────────────────────────────────────────────────────
          Expanded(
            child: incidents.isEmpty
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Fallback hardcoded card when no API data yet
                      _AccidentReportCard(
                        incident: incident, cardBg: _cardBg,
                        cardDark: _cardDark, onViewDetails: onViewDetails,
                      ),
                      const SizedBox(height: 14),
                      _TocLocationCard(
                        cardBg: _cardBg, cardDark: _cardDark,
                        onViewDetails: onViewDetails,
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: incidents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final inc = incidents[i];
                      return _ApiAccidentCard(
                        data: inc, cardBg: _cardBg, cardDark: _cardDark,
                        onViewDetails: onViewDetails,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── API incident card (real DB data) ─────────────────────────────────────────

class _ApiAccidentCard extends StatelessWidget {
  const _ApiAccidentCard({
    required this.data,
    required this.cardBg,
    required this.cardDark,
    required this.onViewDetails,
  });

  final Map<String, dynamic> data;
  final Color                cardBg;
  final Color                cardDark;
  final VoidCallback         onViewDetails;

  @override
  Widget build(BuildContext context) {
    final type    = (data['type']    as String? ?? 'Incident').toUpperCase();
    final address = data['address']  as String? ?? 'Unknown location';
    final riderName = (data['rider'] as Map?)?['full_name'] as String? ?? 'Unknown rider';
    final status  = data['status']   as String? ?? 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('NEW ACCIDENT REPORT',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 12,
                    fontWeight: FontWeight.bold, color: cardDark,
                    letterSpacing: 0.5)),
            const Spacer(),
            Text(status, style: TextStyle(fontFamily: 'Montserrat',
                fontSize: 11, color: Colors.grey[600])),
          ]),
          const SizedBox(height: 10),
          Text('$type — $riderName',
              style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14,
                  fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 3),
          Text(address, style: TextStyle(fontFamily: 'Montserrat',
              fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 10),
          const Text('Please respond to incident',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 13,
                  fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onViewDetails,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: cardDark, borderRadius: BorderRadius.circular(20)),
              child: const Text('HIGH PRIORITY',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 11,
                      fontWeight: FontWeight.bold, color: Colors.white,
                      letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification card 1 — Accident report ─────────────────────────────────────

class _AccidentReportCard extends StatelessWidget {
  const _AccidentReportCard({
    required this.incident,
    required this.cardBg,
    required this.cardDark,
    required this.onViewDetails,
  });

  final PatrolIncident incident;
  final Color cardBg;
  final Color cardDark;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(
                'NEW ACCIDENT REPORT',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cardDark,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                'Just now',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const Text(
            'Accident Reported',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            incident.address,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),

          const Text(
            'Please respond to incident',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          // HIGH PRIORITY badge
          GestureDetector(
            onTap: onViewDetails,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'HIGH PRIORITY',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification card 2 — TOC shared location ─────────────────────────────────

class _TocLocationCard extends StatelessWidget {
  const _TocLocationCard({
    required this.cardBg,
    required this.cardDark,
    required this.onViewDetails,
  });

  final Color cardBg;
  final Color cardDark;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Text(
                'TOC Shared Location',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '2m ago',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const Text(
            'Live location shared',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TOC is sharing their live location for this incident.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),

          // View live location button
          GestureDetector(
            onTap: onViewDetails,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'View live location',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1 — Map with notification card ───────────────────────────────────────

class _MapTab extends StatefulWidget {
  const _MapTab({
    required this.incident,
    required this.primaryColor,
    required this.patrollerName,
    required this.onViewDetails,
  });

  final PatrolIncident incident;
  final Color primaryColor;
  final String patrollerName;
  final VoidCallback onViewDetails;

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PatrolHeader(primaryColor: widget.primaryColor, patrollerName: widget.patrollerName),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: _AccidentCard(
            incident: widget.incident,
            primaryColor: widget.primaryColor,
            onViewDetails: widget.onViewDetails,
          ),
        ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.incident.destinationCoordinates,
              zoom: 12,
            ),
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('incident'),
                position: widget.incident.destinationCoordinates,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            },
          ),
        ),
      ],
    );
  }
}

// ── Tab 2 — Profile / Settings ───────────────────────────────────────────────

class _PatrolSettingsTab extends StatefulWidget {
  const _PatrolSettingsTab({
    required this.primaryColor,
    required this.patrollerName,
    required this.patrollerEmail,
    required this.onBack,
  });

  final Color primaryColor;
  final String patrollerName;
  final String patrollerEmail;
  final VoidCallback onBack;

  @override
  State<_PatrolSettingsTab> createState() => _PatrolSettingsTabState();
}

class _PatrolSettingsTabState extends State<_PatrolSettingsTab> {
  bool _pushNotifications = true;
  bool _locationAccess = true;

  static const _bg = Color(0xFFF0F2F4);
  static const _cardDark = Color(0xFF163848);

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want\nto Log out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE05555),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        nav.pop();
                        await AuthService.logout();
                        nav.pushNamedAndRemoveUntil(
                          '/onboarding',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          // ── Page header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ─────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Profile card
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo/pnp.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const FaIcon(
                              FontAwesomeIcons.solidUser,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.patrollerName,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              widget.patrollerEmail,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Edit profile coming soon.',
                              style: TextStyle(fontFamily: 'Montserrat')),
                          duration: Duration(seconds: 2),
                        )),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: widget.primaryColor, width: 1.5),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.penToSquare,
                            size: 16,
                            color: widget.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Edit Profile button
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                    content: Text('Edit profile coming soon.',
                        style: TextStyle(fontFamily: 'Montserrat')),
                    duration: Duration(seconds: 2),
                  )),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8CFD8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Edit Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Notifications section
                const _SectionLabel(label: 'Notifications'),
                const SizedBox(height: 8),
                _SettingsRow(
                  label: 'Push Notifications',
                  trailing: _LabeledSwitch(
                    value: _pushNotifications,
                    onChanged: (v) =>
                        setState(() => _pushNotifications = v),
                    primaryColor: widget.primaryColor,
                  ),
                ),

                const SizedBox(height: 18),

                // Permissions section
                const _SectionLabel(label: 'Permissions'),
                const SizedBox(height: 8),
                _SettingsRow(
                  label: 'Location access',
                  trailing: _LabeledSwitch(
                    value: _locationAccess,
                    onChanged: (v) =>
                        setState(() => _locationAccess = v),
                    primaryColor: widget.primaryColor,
                  ),
                ),

                const SizedBox(height: 18),

                // Maintenance
                const _SectionLabel(label: 'Maintenance'),
                const SizedBox(height: 8),
                _SettingsRow(
                  label: 'System Test',
                  trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SystemTestScreen()),
                  ),
                ),

                const SizedBox(height: 18),

                // About section
                const _SectionLabel(label: 'About'),
                const SizedBox(height: 8),
                _SettingsRow(
                  label: 'Terms & Conditions',
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.black54),
                  onTap: () =>
                      Navigator.pushNamed(context, '/patrol-terms'),
                ),
                const SizedBox(height: 8),
                _SettingsRow(
                  label: 'Privacy Policy',
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.black54),
                  onTap: () =>
                      Navigator.pushNamed(context, '/patrol-privacy'),
                ),

                const SizedBox(height: 32),

                // Log out button
                GestureDetector(
                  onTap: _showLogoutDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: widget.primaryColor, width: 1.5),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.arrowRightFromBracket,
                            size: 14,
                            color: widget.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Log out',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE05555),
                          ),
                        ),
                      ],
                    ),
                  ),
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

// ── Settings helper widgets ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.trailing,
    this.onTap,
  });

  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _LabeledSwitch extends StatelessWidget {
  const _LabeledSwitch({
    required this.value,
    required this.onChanged,
    required this.primaryColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value ? 'on' : 'off',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            color: value ? primaryColor : Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: primaryColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _PatrolBottomNav extends StatelessWidget {
  const _PatrolBottomNav({
    required this.currentIndex,
    required this.navBg,
    required this.onTap,
  });

  final int currentIndex;
  final Color navBg;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const icons = [
      FontAwesomeIcons.bell,
      FontAwesomeIcons.locationDot,
      FontAwesomeIcons.gear,
    ];

    return Container(
      color: navBg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(3, (i) {
            final active = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: active
                    ? BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      )
                    : null,
                child: FaIcon(
                  icons[i],
                  color: Colors.white,
                  size: 22,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Notification card ─────────────────────────────────────────────────────────

class _AccidentCard extends StatelessWidget {
  const _AccidentCard({
    required this.incident,
    required this.primaryColor,
    required this.onViewDetails,
  });

  final PatrolIncident incident;
  final Color primaryColor;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(
              FontAwesomeIcons.triangleExclamation,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Traffic Accident Reported',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  incident.type,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          ElevatedButton(
            onPressed: onViewDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'View Details',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
