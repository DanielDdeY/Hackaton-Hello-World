import '../entities/billetera.dart';
import '../entities/movimiento_economico.dart';

/// Contrato para la gestion economica y transaccional de fichas y experiencia.
abstract interface class EconomiaRepository {
  /// Obtiene la billetera y estado del usuario.
  Future<Billetera> obtenerBilletera(String uid);

  /// Emite actualizaciones en tiempo real de la billetera.
  Stream<Billetera> escucharBilletera(String uid);

  /// Obtiene los ultimos movimientos financieros del usuario.
  Future<List<MovimientoEconomico>> obtenerMovimientos(String uid, {int limite = 20});

  /// Registra una recompensa por completitud o participacion en un favor.
  Future<void> otorgarRecompensaFavor({
    required String uid,
    required String favorId,
    required int fichas,
    required int xp,
  });

  /// Realiza un debito de fichas para consumos como la caja de sorpresas.
  Future<void> gastarFichas({
    required String uid,
    required int fichas,
    required ConceptoMovimiento concepto,
    required String descripcion,
    String? referenciaId,
  });
}
