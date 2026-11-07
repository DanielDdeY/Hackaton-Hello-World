import '../entities/location_result.dart';

abstract interface class LocationProvider {
  /// Returns the current address or throws [LocationUnavailableException].
  Future<String> getCurrentAddress();
}

abstract interface class DetailedLocationProvider implements LocationProvider {
  Future<LocationResult> getCurrentLocation();

  Future<String> resolveAddress(LocationResult location);
}

enum LocationUnavailableReason {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  unavailable,
}

final class LocationUnavailableException implements Exception {
  const LocationUnavailableException([
    this.reason = LocationUnavailableReason.unavailable,
  ]);

  final LocationUnavailableReason reason;
}
