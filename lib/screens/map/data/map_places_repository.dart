import '../models/map_place.dart';

/// Fuente de datos de los sitios que se muestran en el mapa.
///
/// Se usa un [Stream] porque Firestore expone los cambios en tiempo real con
/// `collection('places').snapshots()`. La implementación con Firebase solo
/// tiene que mapear cada documento con [MapPlace.fromMap].
abstract interface class MapPlacesRepository {
  Stream<List<MapPlace>> watchPlaces();
}

/// Implementación temporal con datos de ejemplo en Madrid.
///
/// TODO(firebase): sustituir por `FirebaseMapPlacesRepository` cuando esté
/// disponible la conexión con Firestore. La pantalla no necesita cambios.
class MockMapPlacesRepository implements MapPlacesRepository {
  static final List<MapPlace> _places = [
    MapPlace(
      id: 'biz-cafe-central',
      name: 'Café Central',
      category: 'Cafetería',
      address: 'Calle del Prado, 10',
      latitude: 40.4147,
      longitude: -3.7003,
      rating: 4.6,
      description:
          'Café histórico con música en vivo, ideal para un café tranquilo '
          'o una copa por la noche.',
      createdAt: DateTime(2026, 2, 12),
    ),
    MapPlace(
      id: 'biz-mercado-san-miguel',
      name: 'Mercado de San Miguel',
      category: 'Mercado',
      address: 'Plaza de San Miguel, s/n',
      latitude: 40.4154,
      longitude: -3.7089,
      rating: 4.5,
      description:
          'Mercado gastronómico con puestos de tapas, embutidos y vinos.',
      createdAt: DateTime(2026, 2, 14),
    ),
    MapPlace(
      id: 'biz-la-mallorquina',
      name: 'La Mallorquina',
      category: 'Pastelería',
      address: 'Puerta del Sol, 8',
      latitude: 40.4167,
      longitude: -3.7036,
      rating: 4.4,
      description:
          'Pastelería clásica de Madrid. Prueba el napolitano de chocolate.',
      createdAt: DateTime(2026, 2, 18),
    ),
    MapPlace(
      id: 'biz-callao',
      name: 'El Corte Inglés Callao',
      category: 'Compras',
      address: 'Plaza del Callao, 2',
      latitude: 40.4201,
      longitude: -3.7058,
      rating: 4.2,
      description: 'Centro comercial con terraza mirador en la última planta.',
      createdAt: DateTime(2026, 3, 2),
    ),
    MapPlace(
      id: 'biz-takos-al-pastor',
      name: 'Takos Al Pastor',
      category: 'Restaurante',
      address: 'Calle de la Abada, 2',
      latitude: 40.4138,
      longitude: -3.7047,
      rating: 4.7,
      description: 'Tacos mexicanos auténticos y económicos, siempre lleno.',
      createdAt: DateTime(2026, 3, 5),
    ),
    MapPlace(
      id: 'biz-altafit-atocha',
      name: 'AltaFit Atocha',
      category: 'Gimnasio',
      address: 'Calle de Méndez Álvaro, 8',
      latitude: 40.4093,
      longitude: -3.6932,
      rating: 4.1,
      description: 'Gimnasio con clases dirigidas y horario amplio.',
      createdAt: DateTime(2026, 3, 9),
    ),
    MapPlace(
      id: 'biz-ocho-y-medio',
      name: 'Librería Ocho y Medio',
      category: 'Librería',
      address: 'Calle de Martín de los Heros, 11',
      latitude: 40.4234,
      longitude: -3.7102,
      rating: 4.6,
      description:
          'Librería especializada en cine, con cafetería y proyecciones.',
      createdAt: DateTime(2026, 3, 15),
    ),
    MapPlace(
      id: 'biz-hanso-cafe',
      name: 'HanSo Café',
      category: 'Cafetería',
      address: 'Calle del Pez, 20',
      latitude: 40.4224,
      longitude: -3.7056,
      rating: 4.5,
      description: 'Café de especialidad con brunch y wifi para trabajar.',
      createdAt: DateTime(2026, 3, 21),
    ),
    MapPlace(
      id: 'saved-parque-retiro',
      name: 'Parque del Retiro',
      category: 'Parque',
      address: 'Plaza de la Independencia, 7',
      latitude: 40.4153,
      longitude: -3.6844,
      description:
          'Mi sitio favorito para desconectar, pasear en barca y hacer picnic.',
      kind: PlaceKind.userSaved,
      savedBy: 'Lucía',
      createdAt: DateTime(2026, 4, 1),
    ),
    MapPlace(
      id: 'saved-azotea-circulo',
      name: 'Azotea del Círculo de Bellas Artes',
      category: 'Mirador',
      address: 'Calle de Alcalá, 42',
      latitude: 40.4184,
      longitude: -3.6966,
      rating: 4.4,
      description: 'Las mejores vistas de Madrid al atardecer.',
      kind: PlaceKind.userSaved,
      savedBy: 'Daniel',
      createdAt: DateTime(2026, 4, 6),
    ),
    MapPlace(
      id: 'saved-templo-debod',
      name: 'Templo de Debod',
      category: 'Monumento',
      address: 'Calle de Ferraz, 1',
      latitude: 40.4240,
      longitude: -3.7177,
      description: 'Templo egipcio con puestas de sol espectaculares.',
      kind: PlaceKind.userSaved,
      savedBy: 'Marta',
      createdAt: DateTime(2026, 4, 11),
    ),
    MapPlace(
      id: 'saved-casa-encendida',
      name: 'La Casa Encendida',
      category: 'Cultura',
      address: 'Ronda de Valencia, 2',
      latitude: 40.4062,
      longitude: -3.6935,
      description: 'Centro cultural con exposiciones gratuitas y talleres. Muy recomendable.',
      kind: PlaceKind.userSaved,
      savedBy: 'Iván',
      createdAt: DateTime(2026, 4, 17),
    ),
  ];

  @override
  Stream<List<MapPlace>> watchPlaces() async* {
    // Pequeño retardo para simular la carga desde la red.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    yield List<MapPlace>.unmodifiable(_places);
  }
}
