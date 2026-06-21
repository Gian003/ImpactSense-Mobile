import 'package:google_maps_flutter/google_maps_flutter.dart';

class PatrolIncident {
  const PatrolIncident({
    this.id,
    required this.type,
    required this.address,
    required this.incidentCoordinates,
    required this.destinationCoordinates,
    required this.reportedAt,
    required this.reportedBy,
    this.tocOperator = 'TOC Operator',
  });

  final int?   id;                       // backend incident ID — null for hardcoded/demo data
  final String type;
  final String address;
  final LatLng incidentCoordinates;      // accident location (car crash marker)
  final LatLng destinationCoordinates;   // pin destination (where patrol heads)
  final String reportedAt;
  final String reportedBy;
  final String tocOperator;

  /// Build from the Pusher patrol.dispatched event payload.
  factory PatrolIncident.fromDispatch(Map<String, dynamic> data) {
    final lat = (data['latitude']  as num).toDouble();
    final lng = (data['longitude'] as num).toDouble();
    return PatrolIncident(
      id:                     data['incident_id'] as int?,
      type:                   data['type']        as String? ?? 'Incident',
      address:                data['address']     as String? ?? 'Unknown location',
      incidentCoordinates:    LatLng(lat, lng),
      destinationCoordinates: LatLng(lat, lng),
      reportedAt:             data['dispatched_at'] as String? ?? '',
      reportedBy:             (data['rider']?['full_name'] as String?) ?? 'Unknown rider',
      tocOperator:            data['toc_operator']  as String? ?? 'TOC Operator',
    );
  }
}
