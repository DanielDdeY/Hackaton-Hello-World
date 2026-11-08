import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'last_location_store.dart';

/// Motivo por el que no se pudo obtener la ubicación del usuario.
enum LocationFailure {
  /// GPS desactivado en el dispositivo y sin ninguna posición guardada.
  serviceDisabled,

  /// Permiso denegado por el usuario (aún se puede volver a pedir).
  permissionDenied,

  /// Permiso denegado de forma permanente (hay que abrir ajustes).
  permissionDeniedForever,

  /// La petición tardó demasiado en responder.
  timeout,

  /// Cualquier otro error (permiso imposible de determinar, plugin ausente…).
  error,
}

/// Resultado de pedir la ubicación: o bien hay posición o bien el motivo.
@immutable
class LocationResult {
  const LocationResult.success(LatLng this.location, {this.isLastKnown = false})
    : failure = null;

  const LocationResult.failure(LocationFailure this.failure)
    : location = null,
      isLastKnown = false;

  /// Posición actual, si se pudo obtener.
  final LatLng? location;

  /// Motivo del fallo, si lo hubo.
  final LocationFailure? failure;

  /// `true` si la posición no es en vivo (es la última conocida o guardada).
  final bool isLastKnown;

  bool get isSuccess => location != null;
}

/// Fuente de la ubicación del usuario. Permite inyectar una
/// implementación falsa en los tests.
abstract interface class MapLocationProvider {
  /// Pide la ubicación actual. Si el GPS está apagado o falla, devuelve la
  /// última posición conocida/guardada en vez de fallar. Nunca lanza
  /// excepciones.
  Future<LocationResult> currentLocation();

  /// Emite posiciones nuevas (en vivo) y, si el GPS se corta o está apagado,
  /// la última posición conocida marcada como `isLastKnown`. Nunca lanza
  /// errores: ante cualquier fallo se queda en el último punto.
  Stream<LocationResult> watch();
}

/// Implementación real basada en `geolocator`.
class GeolocatorLocationProvider implements MapLocationProvider {
  GeolocatorLocationProvider({LastLocationStore? store})
    : _externalStore = store;

  /// Límite global de espera: si el sistema no responde (o el plugin no
  /// está disponible), se devuelve [LocationFailure.timeout] en vez de
  /// dejar la pantalla de carga bloqueada para siempre.
  static const Duration _timeout = Duration(seconds: 10);

  static const LocationSettings _liveSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 50,
  );

  final LastLocationStore? _externalStore;
  LastLocationStore? _store;
  bool _hasLiveLocation = false;

  Future<LastLocationStore> _resolveStore() async {
    if (_store != null) return _store!;
    if (_externalStore != null) {
      _store = _externalStore;
    } else {
      try {
        _store = await SharedPreferencesLastLocationStore.create();
      } catch (_) {
        // Preferencias no disponibles (p. ej. entorno de tests): se usa la
        // caché en memoria.
        _store = InMemoryLastLocationStore();
      }
    }
    return _store!;
  }

  @override
  Future<LocationResult> currentLocation() async {
    try {
      return await _resolveLocation().timeout(_timeout);
    } on TimeoutException {
      return const LocationResult.failure(LocationFailure.timeout);
    } catch (_) {
      return const LocationResult.failure(LocationFailure.error);
    }
  }

  Future<LocationResult> _resolveLocation() async {
    final store = await _resolveStore();

    // 1. Permiso. Sin él solo se puede recurrir a la posición guardada.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final hasPermission =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (!hasPermission) {
      final saved = await _lastKnown(store);
      if (saved != null) {
        return LocationResult.success(saved, isLastKnown: true);
      }
      return LocationResult.failure(
        permission == LocationPermission.deniedForever
            ? LocationFailure.permissionDeniedForever
            : LocationFailure.permissionDenied,
      );
    }

    // 2. Intento la posición actual.
    var failure = LocationFailure.error;
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: _liveSettings,
        );
        final location = LatLng(position.latitude, position.longitude);
        await store.write(location);
        _hasLiveLocation = true;
        return LocationResult.success(location);
      }
      failure = LocationFailure.serviceDisabled;
    } on TimeoutException {
      failure = LocationFailure.timeout;
    } catch (_) {
      failure = LocationFailure.error;
    }

    // 3. GPS apagado o error: última posición conocida o guardada.
    final saved = await _lastKnown(store);
    if (saved != null) return LocationResult.success(saved, isLastKnown: true);
    return LocationResult.failure(failure);
  }

  @override
  Stream<LocationResult> watch() {
    final controller = StreamController<LocationResult>();
    StreamSubscription<Position>? positionSubscription;
    StreamSubscription<ServiceStatus>? serviceSubscription;
    var initialized = false;

    Future<void> emitSaved() async {
      final store = await _resolveStore();
      final saved = await _lastKnown(store);
      if (saved != null && !controller.isClosed) {
        controller.add(LocationResult.success(saved, isLastKnown: true));
      }
    }

    Future<void> startPositions() async {
      if (positionSubscription != null) return;
      try {
        positionSubscription =
            Geolocator.getPositionStream(
              locationSettings: _liveSettings,
            ).listen(
              (position) async {
                final location = LatLng(position.latitude, position.longitude);
                _hasLiveLocation = true;
                if (!controller.isClosed) {
                  controller.add(LocationResult.success(location));
                }
                final store = await _resolveStore();
                store.write(location);
              },
              onError: (_) {
                // Sin posiciones nuevas: el mapa se queda en el último punto.
              },
            );
      } catch (_) {
        // El dispositivo no soporta el stream de posiciones.
      }
    }

    Future<void> init() async {
      if (initialized) return;
      initialized = true;
      try {
        // La primera posición puede ser la guardada (GPS apagado, primer
        // arranque, etc.). Si ya hay posición en vivo no se avisa.
        if (!_hasLiveLocation) await emitSaved();

        final permission = await Geolocator.checkPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return;
        }
        await startPositions();

        // Si el GPS se apaga en mitad del uso, se avisa con la última
        // posición conocida; al reactivarse se retoman las posiciones live.
        try {
          serviceSubscription = Geolocator.getServiceStatusStream().listen((
            status,
          ) async {
            if (status == ServiceStatus.disabled) {
              await emitSaved();
            } else {
              await startPositions();
            }
          }, onError: (_) {});
        } catch (_) {
          // Estado del servicio no soportado en esta plataforma.
        }
      } catch (_) {
        // Sin permiso o sin soporte: el mapa se queda en el último punto.
      }
    }

    controller.onListen = init;
    controller.onCancel = () async {
      await positionSubscription?.cancel();
      await serviceSubscription?.cancel();
    };
    return controller.stream;
  }

  Future<LatLng?> _lastKnown(LastLocationStore store) async {
    final saved = await store.read();
    if (saved != null) return saved;
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
    } catch (_) {
      // La caché del sistema no está disponible.
    }
    return null;
  }
}
