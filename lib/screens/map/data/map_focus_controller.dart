import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Solicita que el mapa centre la cámara en una alerta concreta.
class MapFocusController extends ChangeNotifier {
  LatLng? _target;

  LatLng? get target => _target;

  void focus(LatLng target) {
    _target = target;
    notifyListeners();
  }

  void clear() {
    _target = null;
  }
}
