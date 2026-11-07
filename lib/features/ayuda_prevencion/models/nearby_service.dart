/// Servicio de emergencia cercano obtenido vía Overpass API (OpenStreetMap).
class NearbyService {
  const NearbyService({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.phoneNumber,
    this.category,
  });

  /// Nombre del lugar (ej. "Hospital Nacional Dos de Mayo").
  final String name;

  final double latitude;
  final double longitude;

  /// Distancia desde la ubicación del usuario, en metros.
  final double distanceMeters;

  /// Teléfono registrado en OSM (`phone` / `contact:phone`), si existe.
  final String? phoneNumber;

  /// Categoría OSM (hospital, police, fire_station, ...).
  final String? category;

  /// Distancia legible: "350 m" o "1.2 km".
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  Uri? get dialUri => phoneNumber == null
      ? null
      : Uri(scheme: 'tel', path: phoneNumber!.replaceAll(' ', ''));
}
