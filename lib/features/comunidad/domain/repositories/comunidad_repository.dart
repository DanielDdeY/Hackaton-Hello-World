import '../entities/evento_comunitario.dart';
import '../entities/favor.dart';
import '../entities/resumen_hoy.dart';
import '../entities/vecino_ranking.dart';

abstract class ComunidadRepository {
  Future<ResumenHoy> obtenerResumenHoy();

  Future<List<Favor>> obtenerFavores({
    CategoriaFavor? categoria,
    TamanoFavor? tamano,
    bool soloConCupo = false,
  });

  Future<Favor> obtenerFavorPorId(String id);

  /// Acepta un favor respetando el cupo disponible
  Future<void> aceptarFavor(String favorId);

  /// Marca el favor como completado por el ayudante
  Future<void> marcarTerminado(String favorId);

  /// Doble confirmación: el vecino ayudado califica y confirma el favor
  Future<void> confirmarYCalificar(String favorId, double calificacion);

  Future<List<EventoComunitario>> obtenerEventos();

  Future<void> responderEvento(String eventoId, RespuestaEvento respuesta);

  Future<List<VecinoRanking>> obtenerRanking({String ambito = 'cuadra'});

  Future<BuenVecinoSemana?> obtenerBuenVecinoSemana();

  Future<void> nominarBuenVecino(String destinoUid, String motivo);

  Future<void> reportarContenido(String tipo, String id, String motivo);
}

