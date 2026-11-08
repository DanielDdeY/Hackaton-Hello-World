import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/nearby_service.dart';

/// Servicio de emergencia cercano vía Overpass API (OpenStreetMap).
///
/// Gratis y sin API key. Categorías consultadas:
/// hospital, clinic, doctors, pharmacy, police, fire_station.
abstract final class OverpassService {
  /// Endpoints en orden de preferencia (fallback si uno falla).
  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  static const _categories = [
    'hospital',
    'clinic',
    'doctors',
    'pharmacy',
    'police',
    'fire_station',
  ];

  static const _radiusMeters = 3000;
  static const _timeout = Duration(seconds: 25);

  /// Busca servicios de emergencia dentro de [_radiusMeters] de [lat]/[lon].
  ///
  /// Lanza [OverpassException] si todos los endpoints fallan.
  static Future<List<NearbyService>> findNearby({
    required double lat,
    required double lon,
  }) async {
    final query = _buildQuery(lat, lon);

    Object? lastError;
    for (final endpoint in _endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {'data': query},
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          return _parse(response.body, lat, lon);
        }
        lastError = 'HTTP ${response.statusCode}';
      } catch (e) {
        lastError = e;
      }
    }
    throw OverpassException(
      'No se pudo consultar el directorio cercano: $lastError',
    );
  }

  static String _buildQuery(double lat, double lon) {
    final filter = _categories.map((c) => '"$c"').join('|');
    return '''
[out:json][timeout:25];
(
  node["amenity"~"$filter"](around:$_radiusMeters,$lat,$lon);
  way["amenity"~"$filter"](around:$_radiusMeters,$lat,$lon);
);
out center tags;
''';
  }

  static List<NearbyService> _parse(
    String body,
    double userLat,
    double userLon,
  ) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final elements = decoded['elements'] as List<dynamic>? ?? [];

    final results = <NearbyService>[];
    for (final element in elements) {
      final map = element as Map<String, dynamic>;
      final tags = map['tags'] as Map<String, dynamic>? ?? {};

      final name = tags['name'] as String?;
      if (name == null || name.isEmpty) continue;

      // `way` no tiene lat/lon propio: se usa `center`.
      final center = map['center'] as Map<String, dynamic>?;
      final lat =
          (map['lat'] as num?)?.toDouble() ??
          (center?['lat'] as num?)?.toDouble();
      final lon =
          (map['lon'] as num?)?.toDouble() ??
          (center?['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;

      final phone =
          (tags['phone'] ??
                  tags['contact:phone'] ??
                  tags['contact:mobile'] ??
                  tags['emergency:phone'])
              as String?;

      results.add(
        NearbyService(
          name: name,
          latitude: lat,
          longitude: lon,
          distanceMeters: _haversine(userLat, userLon, lat, lon),
          phoneNumber: (phone == null || phone.isEmpty) ? null : phone,
          category: tags['amenity'] as String?,
        ),
      );
    }

    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }

  /// Distancia en metros entre dos coordenadas (fórmula de Haversine).
  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // radio de la Tierra en metros
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double deg) => deg * math.pi / 180;
}

/// Error al consultar Overpass API.
class OverpassException implements Exception {
  const OverpassException(this.message);
  final String message;

  @override
  String toString() => message;
}
