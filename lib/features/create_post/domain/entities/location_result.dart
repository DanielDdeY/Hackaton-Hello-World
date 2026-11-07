final class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.isLastKnown = false,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final bool isLastKnown;

  String get coordinateLabel =>
      'Cerca de ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
}
