/// Rareza de los articulos coleccionables de la mascota.
enum RarezaItem {
  comun('Comun', 0.70),
  raro('Raro', 0.27),
  legendario('Legendario', 0.03);

  const RarezaItem(this.etiqueta, this.probabilidadGrupo);
  final String etiqueta;
  final double probabilidadGrupo;
}

/// Articulo o accesorio equipable en el Cuy.
class ItemMascota {
  const ItemMascota({
    required this.id,
    required this.nombre,
    required this.rareza,
    required this.probabilidad,
    required this.assetPath,
    this.dx = 0.0,
    this.dy = 0.0,
    this.escala = 1.0,
  });

  final String id;
  final String nombre;
  final RarezaItem rareza;
  final double probabilidad;
  final String assetPath;
  final double dx;
  final double dy;
  final double escala;

  bool get tieneAsset => assetPath.isNotEmpty;

  /// Catalogo oficial de articulos de la Caja 1.
  static const List<ItemMascota> catalogoOficial = [
    ItemMascota(
      id: 'sombrero',
      nombre: 'Sombrero Clásico',
      rareza: RarezaItem.comun,
      probabilidad: 0.40,
      assetPath: 'assets/mascota/items/sombrero.svg',
      dx: 0.0,
      dy: -10.0,
      escala: 1.0,
    ),
    ItemMascota(
      id: 'sombrero-papel-barco',
      nombre: 'Barco de Papel',
      rareza: RarezaItem.comun,
      probabilidad: 0.30,
      assetPath: 'assets/mascota/items/sombrero-papel-barco.svg',
      dx: 0.0,
      dy: -5.0,
      escala: 0.95,
    ),
    ItemMascota(
      id: 'fiesta',
      nombre: 'Gorrito de Fiesta',
      rareza: RarezaItem.raro,
      probabilidad: 0.18,
      assetPath: 'assets/mascota/items/fiesta.svg',
      dx: 0.0,
      dy: -22.0,
      escala: 0.95,
    ),
    ItemMascota(
      id: 'vikingo',
      nombre: 'Casco Vikingo',
      rareza: RarezaItem.raro,
      probabilidad: 0.09,
      assetPath: 'assets/mascota/items/vikingo.svg',
      dx: 0.0,
      dy: -18.0,
      escala: 1.35,
    ),
    ItemMascota(
      id: 'mugiwara',
      nombre: 'Sombrero Mugiwara',
      rareza: RarezaItem.legendario,
      probabilidad: 0.03,
      assetPath: 'assets/mascota/items/mugiwara.svg',
      dx: 0.0,
      dy: -8.0,
      escala: 1.15,
    ),
  ];

  static ItemMascota? porId(String? id) {
    if (id == null || id.isEmpty) return null;
    // Soporte de compatibilidad con alias anteriores
    final idNormalizado = switch (id) {
      'piruleta' => 'fiesta',
      'shrek' => 'vikingo',
      _ => id,
    };
    return catalogoOficial.cast<ItemMascota?>().firstWhere(
      (item) => item?.id == idNormalizado,
      orElse: () => null,
    );
  }
}
