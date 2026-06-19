import 'package:google_maps_flutter/google_maps_flutter.dart';

class PatrolIncident {
  const PatrolIncident({
    required this.type,
    required this.address,
    required this.incidentCoordinates,
    required this.destinationCoordinates,
    required this.reportedAt,
    required this.reportedBy,
    this.tocOperator = 'TOC Operator',
  });

  final String type;
  final String address;
  final LatLng incidentCoordinates;   // accident location (car crash marker)
  final LatLng destinationCoordinates; // pin destination (where patrol heads)
  final String reportedAt;
  final String reportedBy;
  final String tocOperator;
}
