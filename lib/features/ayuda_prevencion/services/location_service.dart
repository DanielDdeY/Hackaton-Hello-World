import 'package:geolocator/geolocator.dart';

/// Resultado de la obtención de ubicación.
class LocationResult {
  const LocationResult.success(this.position)
    : error = null,
      permissionDenied = false;

  const LocationResult.failure(this.error, {this.permissionDenied = false})
    : position = null;

  final Position? position;
  final String? error;
  final bool permissionDenied;

  bool get isSuccess => position != null;
}

/// Acceso a la ubicación del dispositivo con manejo de permisos.
abstract final class LocationService {
  /// Obtiene la posición actual.
  ///
  /// Maneja: servicios desactivados, permiso denegado y errores inesperados.
  static Future<LocationResult> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult.failure(
          'Los servicios de ubicación están desactivados.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(
          'Permiso de ubicación denegado.',
          permissionDenied: true,
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(
          'Permiso de ubicación bloqueado. Actívalo en la configuración.',
          permissionDenied: true,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationResult.success(position);
    } catch (e) {
      return LocationResult.failure('No se pudo obtener la ubicación: $e');
    }
  }
}
