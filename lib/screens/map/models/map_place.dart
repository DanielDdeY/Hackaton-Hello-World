import 'package:latlong2/latlong.dart';

/// Tipo de sitio que se puede mostrar en el mapa.
enum PlaceKind {
  business,
  userSaved;

  /// Etiqueta legible para mostrar en la interfaz.
  String get label => switch (this) {
    PlaceKind.business => 'Negocio',
    PlaceKind.userSaved => 'Guardado',
  };

  static PlaceKind fromValue(Object? value) {
    return value == 'userSaved' || value == 'user_saved'
        ? PlaceKind.userSaved
        : PlaceKind.business;
  }
}

/// Un negocio o un sitio guardado por un usuario.
///
/// El modelo está pensado para mapear directamente un documento de Firestore:
/// [toMap] genera el mismo formato que espera [MapPlace.fromMap]. Cuando se
/// conecte Firebase solo hay que leer los documentos con `fromMap`.
class MapPlace {
  const MapPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.description = '',
    this.address = '',
    this.rating,
    this.kind = PlaceKind.business,
    this.savedBy,
    this.createdAt,
  });

  /// Identificador del documento (en Firestore sería el id del documento).
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String description;
  final String address;

  /// Valoración media de 0 a 5 (solo negocios).
  final double? rating;
  final PlaceKind kind;

  /// Nombre del usuario que guardó el sitio (solo [PlaceKind.userSaved]).
  final String? savedBy;
  final DateTime? createdAt;

  bool get isBusiness => kind == PlaceKind.business;

  LatLng get location => LatLng(latitude, longitude);

  factory MapPlace.fromMap(String id, Map<String, dynamic> data) {
    return MapPlace(
      id: id,
      name: data['name'] as String? ?? 'Sin nombre',
      category: data['category'] as String? ?? 'Otros',
      latitude: _toDouble(data['latitude']) ?? 0,
      longitude: _toDouble(data['longitude']) ?? 0,
      description: data['description'] as String? ?? '',
      address: data['address'] as String? ?? '',
      rating: _toDouble(data['rating']),
      kind: PlaceKind.fromValue(data['kind']),
      savedBy: data['savedBy'] as String?,
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'address': address,
      'rating': rating,
      'kind': kind.name,
      'savedBy': savedBy,
      'createdAt': createdAt,
    };
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    // Soporta un Timestamp de Firestore sin depender de firebase_firestore.
    try {
      final dynamic dynamicValue = value;
      final converted = dynamicValue.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // El valor no es un Timestamp de Firestore.
    }
    return null;
  }
}
