import '../entities/mascota.dart';
import '../services/caja_sorpresas_service.dart';

/// Contrato para persistir y gestionar el estado del Cuy de un vecino.
abstract interface class MascotaRepository {
  Future<Mascota> obtenerMascota(String uid);

  Stream<Mascota> escucharMascota(String uid);

  Future<void> actualizarNombre(String uid, String nuevoNombre);

  Future<void> equiparItem(String uid, String? itemId);

  Future<ResultadoAperturaCaja> abrirCaja({
    required String uid,
    required int fichasDisponibles,
  });
}
