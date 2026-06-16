import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:impactsense/core/services/routing_service.dart';

class LiveNavigationScreen extends StatefulWidget {
  const LiveNavigationScreen({super.key, this.onBack});

  /// Called by the back button when this widget is embedded in an IndexedStack.
  final VoidCallback? onBack;

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen> {
  static const _primaryColor = Color(0xFF1A6B78);

  // Default to Urdaneta, Pangasinan
  static const _defaultCenter = LatLng(15.9754, 120.5697);

  final _mapController = MapController();
  final _searchController = TextEditingController();

  LatLng? _currentPosition;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  List<GeocodingResult> _suggestions = [];

  bool _loadingLocation = true;
  bool _loadingRoute = false;
  bool _showSuggestions = false;

  StreamSubscription<Position>? _locationStream;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _locationStream?.cancel();
    _searchController.dispose();
    _searchDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ── Location ────────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      setState(() => _loadingLocation = false);
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final latLng = LatLng(pos.latitude, pos.longitude);
    if (mounted) {
      setState(() {
        _currentPosition = latLng;
        _loadingLocation = false;
      });
      _mapController.move(latLng, 14.0);
    }

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((p) {
      if (mounted) {
        setState(() => _currentPosition = LatLng(p.latitude, p.longitude));
      }
    });
  }

  void _centerOnMe() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 14.0);
    }
  }

  // ── Search / routing ────────────────────────────────────────────────────────

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
      _routePoints = [];
      _loadingRoute = true;
    });

    if (_currentPosition != null) {
      final route =
          await RoutingService.fetchRoute(_currentPosition!, result.position);
      if (mounted) {
        setState(() {
          _routePoints = route;
          _loadingRoute = false;
        });
        if (route.isNotEmpty) {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(route),
              padding: const EdgeInsets.all(60),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() => _loadingRoute = false);
        _mapController.move(result.position, 14.0);
      }
    }
  }

  void _clearDestination() {
    setState(() {
      _destination = null;
      _routePoints = [];
      _searchController.clear();
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Map ──────────────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition ?? _defaultCenter,
            initialZoom: 13.0,
            onTap: (_, __) =>
                setState(() => _showSuggestions = false),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.impactsense.app',
            ),
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: _primaryColor,
                    strokeWidth: 5.0,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (_currentPosition != null)
                  Marker(
                    point: _currentPosition!,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                if (_destination != null)
                  Marker(
                    point: _destination!,
                    width: 36,
                    height: 42,
                    alignment: Alignment.topCenter,
                    child: const FaIcon(
                      FontAwesomeIcons.locationPin,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),
              ],
            ),
          ],
        ),

        // ── Loading overlay ──────────────────────────────────────────────────
        if (_loadingLocation)
          const Center(
            child: CircularProgressIndicator(color: _primaryColor),
          ),

        // ── Search overlay ───────────────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Back / home button
                  _CircleButton(
                    onTap: widget.onBack ?? () => Navigator.pop(context),
                    child: const Icon(Icons.chevron_left,
                        size: 22, color: Colors.black54),
                  ),
                  const SizedBox(width: 8),

                  // Search field
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
                          const FaIcon(
                            FontAwesomeIcons.magnifyingGlass,
                            color: _primaryColor,
                            size: 15,
                          ),
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
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 13),
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

              // Suggestions
              if (_showSuggestions)
                Container(
                  margin: const EdgeInsets.only(top: 4, left: 46),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = _suggestions[i];
                      return ListTile(
                        dense: true,
                        leading: const FaIcon(
                          FontAwesomeIcons.locationDot,
                          color: _primaryColor,
                          size: 15,
                        ),
                        title: Text(
                          s.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Montserrat', fontSize: 12),
                        ),
                        onTap: () => _selectDestination(s),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // ── Re-center FAB ────────────────────────────────────────────────────
        Positioned(
          bottom: 20,
          right: 14,
          child: _CircleButton(
            onTap: _centerOnMe,
            child: const FaIcon(
              FontAwesomeIcons.locationArrow,
              color: _primaryColor,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
