import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Radio máximo (en metros) que el mapa permite recorrer desde la
/// ubicación del usuario.
const double kMapRadiusMeters = 1800;

const Distance _distance = Distance();

/// Distancia en metros entre dos puntos (haversine).
double distanceMeters(LatLng from, LatLng to) {
  return _distance.as(LengthUnit.Meter, from, to);
}

/// `true` si [point] está a [radiusMeters] o menos de [center].
bool isWithinRadius(
  LatLng center,
  LatLng point, {
  double radiusMeters = kMapRadiusMeters,
}) {
  return distanceMeters(center, point) <= radiusMeters;
}

/// Devuelve [point] tal cual si está dentro del círculo; si está fuera,
/// lo devuelve sobre el borde del círculo (misma dirección).
LatLng clampToRadius(
  LatLng center,
  LatLng point, {
  double radiusMeters = kMapRadiusMeters,
}) {
  final distance = distanceMeters(center, point);
  if (distance <= radiusMeters) return point;
  final bearing = _distance.bearing(center, point);
  return _distance.offset(center, radiusMeters, bearing);
}

/// Restricción circular para `MapOptions.cameraConstraint`: el centro de
/// la cámara nunca puede salirse de [radiusMeters] alrededor de [center].
class RadiusCameraConstraint extends CameraConstraint {
  const RadiusCameraConstraint({
    required this.center,
    this.radiusMeters = kMapRadiusMeters,
  });

  /// Punto central del círculo (la ubicación del usuario).
  final LatLng center;

  /// Radio en metros.
  final double radiusMeters;

  @override
  MapCamera? constrain(MapCamera camera) {
    if (distanceMeters(center, camera.center) <= radiusMeters) {
      return camera;
    }
    return camera.withPosition(
      center: clampToRadius(center, camera.center, radiusMeters: radiusMeters),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RadiusCameraConstraint &&
        other.center == center &&
        other.radiusMeters == radiusMeters;
  }

  @override
  int get hashCode => Object.hash(center, radiusMeters);
}
