import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import '../../domain/services/address_resolver.dart';

final class GeocodingAddressResolver implements AddressResolver {
  const GeocodingAddressResolver({this.lookup = _deviceLookup});

  final Future<List<geocoding.Placemark>> Function(double, double) lookup;

  @override
  Future<String?> resolve(double latitude, double longitude) async {
    final placemarks = await lookup(latitude, longitude);
    for (final place in placemarks) {
      final street = [place.thoroughfare, place.subThoroughfare]
          .whereType<String>()
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .join(' ');
      final parts =
          [
                street.isEmpty ? place.street : street,
                place.subLocality,
                place.locality,
              ]
              .whereType<String>()
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty);
      if (parts.isNotEmpty) return parts.toSet().join(', ');
    }
    return null;
  }

  static Future<List<geocoding.Placemark>> _deviceLookup(
    double latitude,
    double longitude,
  ) async {
    if (kIsWeb ||
        !const {
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)) {
      return const [];
    }
    return geocoding.Geocoding(locale: const Locale('es', 'PE'))
        .placemarkFromCoordinates(latitude, longitude);
  }
}
