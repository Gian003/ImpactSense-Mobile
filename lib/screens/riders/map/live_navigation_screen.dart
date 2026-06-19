import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:impactsense/core/services/routing_service.dart';

class LiveNavigationScreen extends StatefulWidget {
  const LiveNavigationScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen> {
  static const _primaryColor = Color(0xFF1A6B78);
  static const _defaultCenter = LatLng(15.9754, 120.5697);

  GoogleMapController? _mapController;
  final _searchController = TextEditingController();

  LatLng? _currentPosition;
  double _currentHeading = 0.0;  // bearing in degrees (0 = north)
  bool _navMode = false;          // tilt + follow heading when true

  LatLng? _destination;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<GeocodingResult> _suggestions = [];
  BitmapDescriptor? _arrowIcon;   // loaded from location_tracker.png

  bool _loadingLocation = true;
  bool _loadingRoute = false;
  bool _showSuggestions = false;

  StreamSubscription<Position>? _locationStream;
  Timer? _searchDebounce;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadArrowIcon();
    _initLocation();
  }

  @override
  void dispose() {
    _locationStream?.cancel();
    _searchController.dispose();
    _searchDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Arrow icon ─────────────────────────────────────────────────────────────

  Future<void> _loadArrowIcon() async {
    _arrowIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/icons/location_tracker.png',
    );
    if (mounted) setState(() {});
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (mounted) setState(() => _loadingLocation = false);
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    if (mounted) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentPosition = latLng;
        _currentHeading = pos.heading >= 0 ? pos.heading : 0.0;
        _loadingLocation = false;
        _markers = _buildMarkers(latLng, _currentHeading);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    }

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onLocationUpdate);
  }

  void _onLocationUpdate(Position p) {
    if (!mounted) return;
    final pos = LatLng(p.latitude, p.longitude);
    final heading = p.heading >= 0 ? p.heading : 0.0;

    setState(() {
      _currentPosition = pos;
      _currentHeading = heading;
      _markers = _buildMarkers(pos, heading);
    });

    // In nav mode: camera tilts + rotates to follow heading
    if (_navMode && _destination != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: pos,
            zoom: 17,
            tilt: 50,
            bearing: heading,
          ),
        ),
      );
    }
  }

  // Build the current markers set (arrow + optional destination pin)
  Set<Marker> _buildMarkers(LatLng pos, double heading) {
    return {
      Marker(
        markerId: const MarkerId('my_location'),
        position: pos,
        rotation: heading,
        flat: true,                          // stays flat against the map
        anchor: const Offset(0.5, 0.5),      // rotates from center
        icon: _arrowIcon ?? BitmapDescriptor.defaultMarker,
        zIndexInt: 2,
      ),
      if (_destination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };
  }

  // ── Camera ─────────────────────────────────────────────────────────────────

  void _centerOnMe() {
    if (_currentPosition == null) return;
    if (_navMode) {
      // Nav mode: tilted + rotated to heading
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 17,
            tilt: 50,
            bearing: _currentHeading,
          ),
        ),
      );
    } else {
      // Free mode: flat top-down view
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    }
  }

  void _toggleNavMode() {
    setState(() => _navMode = !_navMode);
    _centerOnMe();
  }

  // ── Search / routing ───────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await RoutingService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
        });
      }
    });
  }

  Future<void> _selectDestination(GeocodingResult result) async {
    setState(() {
      _destination = result.position;
      _showSuggestions = false;
      _searchController.text = result.displayName.split(',').first.trim();
      _polylines = {};
      _loadingRoute = true;
      _markers = _buildMarkers(
        _currentPosition ?? _defaultCenter,
        _currentHeading,
      );
    });

    if (_currentPosition != null) {
      final route =
          await RoutingService.fetchRoute(_currentPosition!, result.position);
      if (!mounted) return;
      if (route.isNotEmpty) {
        final minLat = route.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
        final maxLat = route.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
        final minLng = route.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
        final maxLng = route.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: route,
              color: _primaryColor,
              width: 6,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
          };
          _loadingRoute = false;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            70,
          ),
        );
      } else {
        setState(() => _loadingRoute = false);
        _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(result.position, 14));
      }
    } else {
      setState(() => _loadingRoute = false);
      _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(result.position, 14));
    }
  }

  void _clearDestination() {
    setState(() {
      _destination = null;
      _polylines = {};
      _searchController.clear();
      _suggestions = [];
      _showSuggestions = false;
      _navMode = false;
      _markers = _buildMarkers(
        _currentPosition ?? _defaultCenter,
        _currentHeading,
      );
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Google Map ──────────────────────────────────────────────────────
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition ?? _defaultCenter,
            zoom: 14,
          ),
          onMapCreated: (c) {
            _mapController = c;
            if (_currentPosition != null) {
              c.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentPosition!, 15));
            }
          },
          // Use our custom arrow marker so no duplicate dot
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          tiltGesturesEnabled: true,
          markers: _markers,
          polylines: _polylines,
          onTap: (_) => setState(() => _showSuggestions = false),
        ),

        // ── Loading indicator ───────────────────────────────────────────────
        if (_loadingLocation)
          const Center(child: CircularProgressIndicator(color: _primaryColor)),

        // ── Search bar ──────────────────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CircleButton(
                    onTap: widget.onBack ?? () => Navigator.pop(context),
                    child: const Icon(Icons.chevron_left,
                        size: 22, color: Colors.black54),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const FaIcon(FontAwesomeIcons.magnifyingGlass,
                              color: _primaryColor, size: 15),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              decoration: const InputDecoration(
                                hintText: 'Search destination...',
                                hintStyle: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 13),
                              ),
                              style: const TextStyle(
                                  fontFamily: 'Montserrat', fontSize: 13),
                            ),
                          ),
                          if (_loadingRoute)
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _primaryColor),
                              ),
                            )
                          else if (_destination != null)
                            GestureDetector(
                              onTap: _clearDestination,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: FaIcon(FontAwesomeIcons.xmark,
                                    size: 14, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Suggestions dropdown
              if (_showSuggestions)
                Container(
                  margin: const EdgeInsets.only(top: 4, left: 46),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6)
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = _suggestions[i];
                      return ListTile(
                        dense: true,
                        leading: const FaIcon(FontAwesomeIcons.locationDot,
                            color: _primaryColor, size: 15),
                        title: Text(s.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Montserrat', fontSize: 12)),
                        onTap: () => _selectDestination(s),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // ── FABs (bottom right) ─────────────────────────────────────────────
        Positioned(
          bottom: 20,
          right: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nav mode toggle — only visible when a destination is set
              if (_destination != null) ...[
                _CircleButton(
                  color: _navMode ? _primaryColor : Colors.white,
                  onTap: _toggleNavMode,
                  child: FaIcon(
                    FontAwesomeIcons.locationArrow,
                    color: _navMode ? Colors.white : _primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // Re-center
              _CircleButton(
                onTap: _centerOnMe,
                child: const FaIcon(FontAwesomeIcons.crosshairs,
                    color: _primaryColor, size: 16),
              ),
            ],
          ),
        ),

        // ── Nav mode label ──────────────────────────────────────────────────
        if (_navMode)
          Positioned(
            bottom: 76,
            left: 0,
            right: 60,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Navigation Mode  •  Tap arrow to exit',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Circle icon button ─────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.onTap,
    required this.child,
    this.color = Colors.white,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Center(child: child),
      ),
    );
  }
}
