import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:hackaton_hello_world/screens/map/utils/map_geo.dart';

void main() {
  const center = LatLng(40.4168, -3.7038);
  // ~500 m al norte.
  const near = LatLng(40.4213, -3.7038);
  // ~5 km al norte.
  const far = LatLng(40.4618, -3.7038);

  group('radio de 1.8 km', () {
    test('distanceMeters mide la distancia real', () {
      expect(distanceMeters(center, center), 0);
      expect(distanceMeters(center, near), closeTo(500, 20));
      expect(distanceMeters(center, far), greaterThan(kMapRadiusMeters));
    });

    test('isWithinRadius solo acepta puntos dentro del círculo', () {
      expect(isWithinRadius(center, near), isTrue);
      expect(isWithinRadius(center, far), isFalse);
      // Justo en el borde: sigue estando dentro.
      expect(
        isWithinRadius(
          center,
          clampToRadius(center, far),
          radiusMeters: kMapRadiusMeters,
        ),
        isTrue,
      );
    });

    test('clampToRadius devuelve el punto si está dentro', () {
      expect(clampToRadius(center, near), near);
      expect(clampToRadius(center, center), center);
    });

    test('clampToRadius recorta al borde los puntos de fuera', () {
      final clamped = clampToRadius(center, far);

      expect(distanceMeters(center, clamped), closeTo(kMapRadiusMeters, 1));
      expect(isWithinRadius(center, clamped), isTrue);
      // Sigue en la misma dirección (al norte del centro).
      expect(clamped.latitude, greaterThan(center.latitude));
      expect(clamped.longitude, closeTo(center.longitude, 0.001));
    });
  });

  group('RadiusCameraConstraint', () {
    MapCamera cameraAt(LatLng point) {
      return MapCamera(
        crs: const Epsg3857(),
        center: point,
        zoom: 13.5,
        rotation: 0,
        nonRotatedSize: const Size(400, 600),
      );
    }

    test('deja pasar las cámaras dentro del radio', () {
      const constraint = RadiusCameraConstraint(center: center);
      final camera = cameraAt(near);

      expect(constraint.constrain(camera), same(camera));
    });

    test('recorta al borde las cámaras que salen del radio', () {
      const constraint = RadiusCameraConstraint(center: center);
      final constrained = constraint.constrain(cameraAt(far));

      expect(constrained, isNotNull);
      expect(
        distanceMeters(center, constrained!.center),
        closeTo(kMapRadiusMeters, 1),
      );
    });

    test('aplica el radio que se le indique', () {
      const constraint = RadiusCameraConstraint(
        center: center,
        radiusMeters: 1000,
      );
      final constrained = constraint.constrain(cameraAt(far));

      expect(
        distanceMeters(center, constrained!.center),
        closeTo(1000, 1),
      );
    });
  });
}
