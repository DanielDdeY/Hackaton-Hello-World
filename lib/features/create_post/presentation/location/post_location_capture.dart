import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../domain/entities/location_result.dart';
import '../../domain/services/location_provider.dart';

enum PostLocationStatus { loading, ready, unavailable }

mixin PostLocationCapture on ChangeNotifier {
  final addressController = TextEditingController();
  bool _disposed = false;
  bool _addressEdited = false;
  LocationResult? _coordinates;
  LocationUnavailableReason? _failure;
  PostLocationStatus _status = PostLocationStatus.loading;

  LocationResult? get coordinates => _coordinates;
  bool get addressEditedByUser => _addressEdited;
  PostLocationStatus get locationStatus => _status;

  void markAddressEdited(String _) => _addressEdited = true;

  String? get locationNotice {
    if (_coordinates?.isLastKnown ?? false) {
      return 'Usamos la última ubicación conocida. Revísala antes de publicar.';
    }
    if (_status != PostLocationStatus.unavailable) return null;
    return switch (_failure) {
      LocationUnavailableReason.permissionDenied ||
      LocationUnavailableReason.permissionDeniedForever =>
        'Permiso de ubicación denegado. Puedes escribir la dirección.',
      LocationUnavailableReason.serviceDisabled =>
        'El GPS está apagado. Puedes escribir la dirección.',
      LocationUnavailableReason.timeout =>
        'La ubicación tardó demasiado. Puedes escribir la dirección.',
      _ => 'No se pudo obtener tu ubicación. Puedes escribir la dirección.',
    };
  }

  /// Completes when coordinates are available, without waiting for geocoding.
  Future<void> captureLocation(LocationProvider provider) async {
    try {
      if (provider is DetailedLocationProvider) {
        final point = await provider.getCurrentLocation();
        if (_disposed) return;
        _coordinates = point;
        _applyAddress(point.address ?? point.coordinateLabel);
        if (!_addressEdited) unawaited(_resolveAddress(provider, point));
      } else {
        _applyAddress((await provider.getCurrentAddress()).trim());
      }
    } on LocationUnavailableException catch (error) {
      if (_disposed) return;
      _failure = error.reason;
      _applyAddress('');
    }
  }

  Future<void> _resolveAddress(
    DetailedLocationProvider provider,
    LocationResult point,
  ) async {
    try {
      final resolved = await provider.resolveAddress(point);
      if (!_disposed &&
          !_addressEdited &&
          resolved.trim().isNotEmpty &&
          addressController.text != resolved) {
        addressController.text = resolved;
      }
    } on Exception {
      // The coordinates are already available as an editable address.
    }
  }

  void _applyAddress(String address) {
    if (_disposed) return;
    _status = address.isEmpty
        ? PostLocationStatus.unavailable
        : PostLocationStatus.ready;
    if (!_addressEdited && address.isNotEmpty) addressController.text = address;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    addressController.dispose();
    super.dispose();
  }
}
