import '../entities/evento_comunitario.dart';
import '../entities/favor.dart';
import '../entities/vecino_ranking.dart';

abstract class ComunidadRepository {
  String get usuarioActualId;

  Future<List<Favor>> obtenerFavores({
    CategoriaFavor? categoria,
    TamanoFavor? tamano,
    bool soloConCupo = false,
  });

  Future<Favor> obtenerFavorPorId(String id);

  /// Registra un nuevo favor solicitado por un vecino
  Future<Favor> agregarFavor(Favor favor);

  /// Acepta un favor respetando el cupo disponible
  Future<void> aceptarFavor(String favorId);

  /// Marca el favor como completado por el ayudante
  Future<void> marcarTerminado(String favorId);

  /// Doble confirmación: el vecino ayudado califica y confirma el favor
  Future<void> confirmarYCalificar(String favorId, double calificacion);

  Future<List<EventoComunitario>> obtenerEventos();

  Future<void> responderEvento(String eventoId, RespuestaEvento respuesta);

  /// Valida la asistencia física a una reunión vecinal (RF-10)
  Future<void> verificarAsistencia(String eventoId, String codigo);

  Future<String> obtenerDistritoActual();

  Future<List<VecinoRanking>> obtenerRanking({String ambito = 'distrito'});

  Future<VecinoPerfil?> obtenerVecino(String uid);

  Future<BuenVecinoSemana?> obtenerBuenVecinoSemana();

  Future<void> nominarBuenVecino(String destinoUid, String motivo);

  Future<void> reportarContenido(String tipo, String id, String motivo);
}

