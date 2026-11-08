enum TipoEvento {
  reunion('Reunión Vecinal'),
  faena('Faena Comunitaria'),
  taller('Taller / Capacitación'),
  seguridad('Simulacro / Seguridad'),
  cultural('Actividad Cultural'),
  deportivo('Deporte / Recreación');

  const TipoEvento(this.etiqueta);
  final String etiqueta;
}

enum RespuestaEvento { ninguna, voy, meInteresa }

class EventoComunitario {
  const EventoComunitario({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.fecha,
    required this.lugar,
    required this.cuadraNombre,
    required this.organizadorNombre,
    required this.requiereAsistencia,
    this.asistenciasVoy = 0,
    this.asistenciasInteresa = 0,
    this.miRespuesta = RespuestaEvento.ninguna,
    this.asistenciaVerificada = false,
  });

  final String id;
  final String titulo;
  final String descripcion;
  final TipoEvento tipo;
  final DateTime fecha;
  final String lugar;
  final String cuadraNombre;
  final String organizadorNombre;
  final bool requiereAsistencia;
  final int asistenciasVoy;
  final int asistenciasInteresa;
  final RespuestaEvento miRespuesta;
  final bool asistenciaVerificada;

  EventoComunitario copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    TipoEvento? tipo,
    DateTime? fecha,
    String? lugar,
    String? cuadraNombre,
    String? organizadorNombre,
    bool? requiereAsistencia,
    int? asistenciasVoy,
    int? asistenciasInteresa,
    RespuestaEvento? miRespuesta,
    bool? asistenciaVerificada,
  }) {
    return EventoComunitario(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      lugar: lugar ?? this.lugar,
      cuadraNombre: cuadraNombre ?? this.cuadraNombre,
      organizadorNombre: organizadorNombre ?? this.organizadorNombre,
      requiereAsistencia: requiereAsistencia ?? this.requiereAsistencia,
      asistenciasVoy: asistenciasVoy ?? this.asistenciasVoy,
      asistenciasInteresa: asistenciasInteresa ?? this.asistenciasInteresa,
      miRespuesta: miRespuesta ?? this.miRespuesta,
      asistenciaVerificada: asistenciaVerificada ?? this.asistenciaVerificada,
    );
  }
}
