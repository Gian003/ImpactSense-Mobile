import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:impactsense/core/models/patrol_incident.dart';
import 'package:impactsense/core/services/api_client.dart';
import 'package:impactsense/core/services/session_service.dart';

class PatrolAccidentMapScreen extends StatefulWidget {
  const PatrolAccidentMapScreen({super.key});

  @override
  State<PatrolAccidentMapScreen> createState() =>
      _PatrolAccidentMapScreenState();
}

class _PatrolAccidentMapScreenState extends State<PatrolAccidentMapScreen> {
  static const _primaryColor = Color(0xFF1A6B78);
  static const _navBg = Color(0xFF0D3D47);
  static const _cardBg = Color(0xFF163848);

  int _tab = 1; // map tab active

  bool _isOnMyWay  = false;
  bool _hasArrived = false;
  bool _updatingStatus = false;

  late PatrolIncident _incident;
  bool _incidentLoaded = false;

  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    if (_incident.id == null) {
      // No real incident ID — update local state only (demo/fallback data)
      setState(() {
        if (status == 'dispatched') _isOnMyWay  = true;
        if (status == 'resolved')   _hasArrived = true;
      });
      return;
    }

    setState(() => _updatingStatus = true);
    try {
      final token = await SessionService.getToken();
      if (token != null) {
        await ApiClient.patch(
          'patrol/incidents/${_incident.id}/status',
          {'status': status},
          token: token,
        );
      }
    } catch (_) {
      // Non-fatal — update local state regardless
    } finally {
      if (mounted) {
        setState(() {
          _updatingStatus = false;
          if (status == 'dispatched') _isOnMyWay  = true;
          if (status == 'resolved')   _hasArrived = true;
        });
      }
    }
  }

  void _onImOnMyWay()   => _updateStatus('dispatched');
  void _onMarkArrived() => _updateStatus('resolved');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_incidentLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is PatrolIncident) {
        _incident = args;
      } else {
        // Fallback sample data
        _incident = const PatrolIncident(
          type: 'Traffic Accident',
          address: 'Brgy. Cabuloan, Urdaneta City, Pangasinan',
          incidentCoordinates: LatLng(16.015, 120.574),
          destinationCoordinates: LatLng(15.9754, 120.5697),
          reportedAt: 'April 20, 10:30 AM',
          reportedBy: 'Vladimir V. Lalas',
        );
      }
      _incidentLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Full-screen map ────────────────────────────────────────────
            _IncidentMap(
              incident: _incident,
              primaryColor: _primaryColor,
              mapController: (c) => _mapController = c,
            ),

            // ── Back button ────────────────────────────────────────────────
            Positioned(
              top: 12,
              left: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
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
            ),

            // ── Bottom info cards ──────────────────────────────────────────
            if (!_hasArrived)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomCards(
                  incident: _incident,
                  cardBg: _cardBg,
                  primaryColor: _primaryColor,
                  isOnMyWay: _isOnMyWay,
                  onViewMap: () => _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                        _incident.incidentCoordinates, 14),
                  ),
                  onImOnMyWay:   _updatingStatus ? null : _onImOnMyWay,
                  onMarkArrived: _updatingStatus ? null : _onMarkArrived,
                ),
              ),

            // ── Arrived confirmation ───────────────────────────────────────
            if (_hasArrived)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.circleCheck,
                        color: Color(0xFF4CAF50),
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Marked as Arrived',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You have been marked as on-site for this incident.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Back to Dashboard',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _PatrolMapNav(
        currentIndex: _tab,
        navBg: _navBg,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Full-screen map with markers ──────────────────────────────────────────────

class _IncidentMap extends StatelessWidget {
  const _IncidentMap({
    required this.incident,
    required this.primaryColor,
    required this.mapController,
  });

  final PatrolIncident incident;
  final Color primaryColor;
  final ValueChanged<GoogleMapController> mapController;

  LatLng get _center => LatLng(
        (incident.incidentCoordinates.latitude +
                incident.destinationCoordinates.latitude) /
            2,
        (incident.incidentCoordinates.longitude +
                incident.destinationCoordinates.longitude) /
            2,
      );

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _center, zoom: 11.5),
      onMapCreated: mapController,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: {
        // Accident / crash marker (orange)
        Marker(
          markerId: const MarkerId('accident'),
          position: incident.incidentCoordinates,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'Accident Location'),
        ),
        // Reported / destination pin (red)
        Marker(
          markerId: const MarkerId('destination'),
          position: incident.destinationCoordinates,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: incident.address),
        ),
      },
    );
  }
}

// ── Bottom cards (two-panel layout) ──────────────────────────────────────────

class _BottomCards extends StatelessWidget {
  const _BottomCards({
    required this.incident,
    required this.cardBg,
    required this.primaryColor,
    required this.isOnMyWay,
    required this.onViewMap,
    this.onImOnMyWay,
    this.onMarkArrived,
  });

  final PatrolIncident incident;
  final Color cardBg;
  final Color primaryColor;
  final bool isOnMyWay;
  final VoidCallback  onViewMap;
  final VoidCallback? onImOnMyWay;
  final VoidCallback? onMarkArrived;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left — Incident Details
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              color: cardBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Incident Details',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _IncidentRow(
                    icon: FontAwesomeIcons.car,
                    label: 'Type',
                    value: incident.type,
                  ),
                  const SizedBox(height: 8),
                  _IncidentRow(
                    icon: FontAwesomeIcons.locationDot,
                    label: 'Location',
                    value: incident.address,
                  ),
                  const SizedBox(height: 8),
                  _IncidentRow(
                    icon: FontAwesomeIcons.clock,
                    label: 'Reported',
                    value: incident.reportedAt,
                  ),
                  const SizedBox(height: 8),
                  _IncidentRow(
                    icon: FontAwesomeIcons.userGroup,
                    label: 'Reported by',
                    value: incident.reportedBy,
                  ),
                ],
              ),
            ),
          ),

          // Right — TOC Shared Location
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 14, 14, 14),
              color: cardBg.withValues(alpha: 0.92),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOC Shared Location',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // TOC operator info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.solidUser,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident.tocOperator,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Sharing Live Location',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  _TocButton(
                    label: 'View on Map',
                    icon: FontAwesomeIcons.map,
                    onTap: onViewMap,
                    filled: true,
                  ),
                  const SizedBox(height: 6),
                  _TocButton(
                    label: isOnMyWay ? 'On My Way ✓' : 'Im On My Way',
                    icon: FontAwesomeIcons.car,
                    onTap: isOnMyWay ? null : onImOnMyWay,
                    filled: true,
                    confirmed: isOnMyWay,
                  ),
                  const SizedBox(height: 6),
                  _TocButton(
                    label: 'Mark as Arrived',
                    icon: FontAwesomeIcons.circleCheck,
                    onTap: onMarkArrived,
                    filled: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Incident detail row ───────────────────────────────────────────────────────

class _IncidentRow extends StatelessWidget {
  const _IncidentRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final FaIconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaIcon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── TOC action button ─────────────────────────────────────────────────────────

class _TocButton extends StatelessWidget {
  const _TocButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
    this.confirmed = false,
  });

  final String label;
  final FaIconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: filled
              ? (confirmed
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15))
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 12,
              color: filled ? Colors.white : const Color(0xFF163848),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: filled ? Colors.white : const Color(0xFF163848),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _PatrolMapNav extends StatelessWidget {
  const _PatrolMapNav({
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
      FontAwesomeIcons.locationDot,
      FontAwesomeIcons.bell,
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
                child: FaIcon(icons[i], color: Colors.white, size: 22),
              ),
            );
          }),
        ),
      ),
    );
  }
}
