import 'dart:math' as math;

import '../entities/item_mascota.dart';
import '../entities/mascota.dart';

/// Resultado del proceso de apertura de una caja de sorpresas.
class ResultadoAperturaCaja {
  const ResultadoAperturaCaja({
    required this.item,
    required this.esNuevo,
    required this.esGarantizado,
    required this.fichasDevueltas,
    required this.fichasCobradas,
    required this.mascotaActualizada,
  });

  final ItemMascota item;
  final bool esNuevo;
  final bool esGarantizado;
  final int fichasDevueltas;
  final int fichasCobradas;
  final Mascota mascotaActualizada;
}

/// Servicio que gestiona la tirada, calculo de probabilidades, garantia y reembolsos.
class CajaSorpresasService {
  CajaSorpresasService({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  static const int costoCaja = 30;
  static const int reembolsoDuplicado = 15;
  static const int pityGarantizado = 21; // Garantiza legendario en la tirada 21 (tras 20 sin legendario)

  /// Abre una caja aplicando la garantia o el sorteo probabilistico.
  ResultadoAperturaCaja abrirCaja({
    required Mascota mascota,
    required int fichasDisponibles,
  }) {
    final esGratis = mascota.primeraCajaGratis;
    final costo = esGratis ? 0 : costoCaja;

    if (fichasDisponibles < costo) {
      throw StateError('Fichas insuficientes para abrir la caja ($costo requeridas, $fichasDisponibles disponibles)');
    }

    final bool activarPity = mascota.pityCount >= (pityGarantizado - 1);
    ItemMascota itemSeleccionado;
    bool esGarantizado = false;

    if (activarPity) {
      // Garantiza el item legendario del catalogo
      itemSeleccionado = ItemMascota.catalogoOficial.firstWhere(
        (item) => item.rareza == RarezaItem.legendario,
      );
      esGarantizado = true;
    } else {
      itemSeleccionado = _sortearItem();
    }

    final bool yaLoTiene = mascota.tieneItem(itemSeleccionado.id);
    final bool esNuevo = !yaLoTiene;
    final int reembolso = yaLoTiene ? reembolsoDuplicado : 0;

    // Actualiza inventario y contador de garantia
    final nuevosItems = List<String>.from(mascota.itemsDesbloqueados);
    if (esNuevo) {
      nuevosItems.add(itemSeleccionado.id);
    }

    final int nuevoPity = itemSeleccionado.rareza == RarezaItem.legendario ? 0 : (mascota.pityCount + 1);

    final mascotaActualizada = mascota.copyWith(
      itemsDesbloqueados: nuevosItems,
      pityCount: nuevoPity,
      primeraCajaGratis: false,
      cajasAbiertasTotal: mascota.cajasAbiertasTotal + 1,
    );

    return ResultadoAperturaCaja(
      item: itemSeleccionado,
      esNuevo: esNuevo,
      esGarantizado: esGarantizado,
      fichasDevueltas: reembolso,
      fichasCobradas: costo,
      mascotaActualizada: mascotaActualizada,
    );
  }

  /// Sortea un articulo segun las probabilidades acumuladas del catalogo.
  ItemMascota _sortearItem() {
    final roll = _random.nextDouble(); // 0.0 <= roll < 1.0
    double acumulado = 0.0;
    for (final item in ItemMascota.catalogoOficial) {
      acumulado += item.probabilidad;
      if (roll <= acumulado) {
        return item;
      }
    }
    return ItemMascota.catalogoOficial.first;
  }
}
