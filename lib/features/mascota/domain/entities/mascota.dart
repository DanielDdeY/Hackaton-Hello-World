import 'item_mascota.dart';

/// Entidad que representa a la mascota comunitaria (Cuy) de cada vecino.
class Mascota {
  const Mascota({
    required this.nombre,
    this.itemEquipadoId,
    this.itemsDesbloqueados = const <String>[],
    this.pityCount = 0,
    this.primeraCajaGratis = true,
    this.cajasAbiertasTotal = 0,
  });

  final String nombre;
  final String? itemEquipadoId;
  final List<String> itemsDesbloqueados;
  final int pityCount;
  final bool primeraCajaGratis;
  final int cajasAbiertasTotal;

  bool tieneItem(String itemId) => itemsDesbloqueados.contains(itemId);

  ItemMascota? get itemEquipado => ItemMascota.porId(itemEquipadoId);

  Mascota copyWith({
    String? nombre,
    String? itemEquipadoId,
    bool desequipar = false,
    List<String>? itemsDesbloqueados,
    int? pityCount,
    bool? primeraCajaGratis,
    int? cajasAbiertasTotal,
  }) {
    return Mascota(
      nombre: nombre ?? this.nombre,
      itemEquipadoId: desequipar ? null : (itemEquipadoId ?? this.itemEquipadoId),
      itemsDesbloqueados: itemsDesbloqueados ?? this.itemsDesbloqueados,
      pityCount: pityCount ?? this.pityCount,
      primeraCajaGratis: primeraCajaGratis ?? this.primeraCajaGratis,
      cajasAbiertasTotal: cajasAbiertasTotal ?? this.cajasAbiertasTotal,
    );
  }

  factory Mascota.inicial() => const Mascota(
    nombre: 'Mi Cuy',
    itemEquipadoId: null,
    itemsDesbloqueados: <String>[],
    pityCount: 0,
    primeraCajaGratis: true,
    cajasAbiertasTotal: 0,
  );

  factory Mascota.fromMap(Map<String, dynamic> data) {
    return Mascota(
      nombre: data['nombre'] as String? ?? 'Mi Cuy',
      itemEquipadoId: data['itemEquipadoId'] as String?,
      itemsDesbloqueados: (data['itemsDesbloqueados'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[],
      pityCount: (data['pityCount'] as num?)?.toInt() ?? 0,
      primeraCajaGratis: data['primeraCajaGratis'] as bool? ?? true,
      cajasAbiertasTotal: (data['cajasAbiertasTotal'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    if (itemEquipadoId != null) 'itemEquipadoId': itemEquipadoId,
    'itemsDesbloqueados': itemsDesbloqueados,
    'pityCount': pityCount,
    'primeraCajaGratis': primeraCajaGratis,
    'cajasAbiertasTotal': cajasAbiertasTotal,
  };
}
