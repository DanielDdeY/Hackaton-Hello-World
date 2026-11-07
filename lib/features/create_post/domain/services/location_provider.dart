abstract interface class LocationProvider {
  /// Returns the current address or throws [LocationUnavailableException].
  Future<String> getCurrentAddress();
}

final class LocationUnavailableException implements Exception {
  const LocationUnavailableException();
}
