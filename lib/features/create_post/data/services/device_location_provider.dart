import '../../../../screens/map/data/map_location_provider.dart' as map;
import '../../domain/entities/location_result.dart';
import '../../domain/services/address_resolver.dart';
import '../../domain/services/location_provider.dart';

final class DeviceLocationProvider implements DetailedLocationProvider {
  const DeviceLocationProvider({
    required this._mapProvider,
    required this._addressResolver,
  });

  final map.MapLocationProvider _mapProvider;
  final AddressResolver _addressResolver;

  @override
  Future<LocationResult> getCurrentLocation() async {
    final result = await _mapProvider.currentLocation();
    final location = result.location;
    if (location == null) {
      throw LocationUnavailableException(switch (result.failure) {
        map.LocationFailure.permissionDenied =>
          LocationUnavailableReason.permissionDenied,
        map.LocationFailure.permissionDeniedForever =>
          LocationUnavailableReason.permissionDeniedForever,
        map.LocationFailure.serviceDisabled =>
          LocationUnavailableReason.serviceDisabled,
        map.LocationFailure.timeout => LocationUnavailableReason.timeout,
        _ => LocationUnavailableReason.unavailable,
      });
    }
    return LocationResult(
      latitude: location.latitude,
      longitude: location.longitude,
      isLastKnown: result.isLastKnown,
    );
  }

  @override
  Future<String> getCurrentAddress() async =>
      resolveAddress(await getCurrentLocation());

  @override
  Future<String> resolveAddress(LocationResult location) async {
    final knownAddress = location.address?.trim();
    if (knownAddress != null && knownAddress.isNotEmpty) return knownAddress;

    try {
      final address = await _addressResolver
          .resolve(location.latitude, location.longitude)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      final trimmed = address?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    } on Exception {
      // A readable street is optional once the coordinates are available.
    }
    return location.coordinateLabel;
  }
}
