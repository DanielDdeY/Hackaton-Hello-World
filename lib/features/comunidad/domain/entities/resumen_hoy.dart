import 'evento_comunitario.dart';
import 'favor.dart';

class AlertaActiva {
  const AlertaActiva({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.esModoEmergencia,
    this.autor = 'Delegado Vecinal',
  });

  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final bool esModoEmergencia;
  final String autor;
}

class EstadisticasCuadra {
  const EstadisticasCuadra({
    required this.cuadraNombre,
    required this.porcentajeMochilaPreparada,
    required this.favoresCompletadosSemana,
    required this.vecinosActivos,
  });

  final String cuadraNombre;
  final int porcentajeMochilaPreparada;
  final int favoresCompletadosSemana;
  final int vecinosActivos;
}

class ResumenHoy {
  const ResumenHoy({
    this.alertaActiva,
    required this.favoresEnCurso,
    required this.favoresCercanos,
    required this.eventosProximos,
    required this.estadisticasCuadra,
  });

  final AlertaActiva? alertaActiva;
  final List<Favor> favoresEnCurso;
  final List<Favor> favoresCercanos;
  final List<EventoComunitario> eventosProximos;
  final EstadisticasCuadra estadisticasCuadra;
}

