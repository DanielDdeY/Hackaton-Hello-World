import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda la última posición conocida del usuario para poder usarla si el
/// GPS se apaga o la app se reinicia.
abstract interface class LastLocationStore {
  /// Última posición guardada, si la hay.
  Future<LatLng?> read();

  /// Persiste la posición actual.
  Future<void> write(LatLng location);
}

/// Implementación con `shared_preferences` (persiste entre reinicios).
class SharedPreferencesLastLocationStore implements LastLocationStore {
  SharedPreferencesLastLocationStore._(this._prefs);

  static const _keyLatitude = 'last_location_latitude';
  static const _keyLongitude = 'last_location_longitude';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesLastLocationStore> create() async {
    return SharedPreferencesLastLocationStore._(
      await SharedPreferences.getInstance(),
    );
  }

  @override
  Future<LatLng?> read() async {
    final latitude = _prefs.getDouble(_keyLatitude);
    final longitude = _prefs.getDouble(_keyLongitude);
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  @override
  Future<void> write(LatLng location) async {
    await _prefs.setDouble(_keyLatitude, location.latitude);
    await _prefs.setDouble(_keyLongitude, location.longitude);
  }
}

/// Almacén que solo recuerda la posición en memoria (por defecto de
/// [SharedPreferencesLastLocationStore] cuando no hay preferencias
/// disponibles y para tests).
class InMemoryLastLocationStore implements LastLocationStore {
  LatLng? _location;

  @override
  Future<LatLng?> read() async => _location;

  @override
  Future<void> write(LatLng location) async {
    _location = location;
  }
}
