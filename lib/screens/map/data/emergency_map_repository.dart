import 'package:latlong2/latlong.dart';

class EmergencyMapAlert {
  const EmergencyMapAlert({
    required this.id,
    required this.location,
    required this.radiusMeters,
    required this.title,
    required this.type,
    required this.status,
    this.description = '',
    this.photoPath,
  });

  final String id;
  final LatLng location;
  final double radiusMeters;
  final String title;
  final String type;
  final String status;
  final String description;
  final String? photoPath;
}

abstract interface class EmergencyMapRepository {
  Stream<List<EmergencyMapAlert>> watchAlerts();
}

class EmptyEmergencyMapRepository implements EmergencyMapRepository {
  const EmptyEmergencyMapRepository();

  @override
  Stream<List<EmergencyMapAlert>> watchAlerts() =>
      Stream.value(const <EmergencyMapAlert>[]);
}
