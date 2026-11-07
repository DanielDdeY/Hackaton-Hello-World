enum TamanoFavor {
  mini('Mini', '<=15 min', 5, 10),
  medio('Medio', '<=1 h', 15, 30),
  grande('Grande', 'Varias horas', 40, 80),
  comunitario('Comunitario', 'Grupal', 30, 60);

  const TamanoFavor(this.etiqueta, this.duracionAprox, this.monedasBase, this.xpBase);

  final String etiqueta;
  final String duracionAprox;
  final int monedasBase;
  final int xpBase;
}

enum EstadoFavor {
  abierto('Abierto'),
  cuposLlenos('Cupos llenos'),
  aceptado('Aceptado'),
  enCurso('En curso'),
  esperandoConfirmacion('Esperando confirmación'),
  completado('Completado'),
  cancelado('Cancelado');

  const EstadoFavor(this.etiqueta);
  final String etiqueta;
}

enum CategoriaFavor {
  herramientas('Herramientas'),
  compras('Compras y mandados'),
  cuidado('Acompañamiento'),
  reparacion('Reparación'),
  limpieza('Limpieza comunitaria'),
  mascotas('Mascotas'),
  otros('Otros');

  const CategoriaFavor(this.etiqueta);
  final String etiqueta;
}

class ParticipanteFavor {
  const ParticipanteFavor({
    required this.uid,
    required this.nombre,
    required this.estado,
    required this.aceptadoEn,
    this.terminadoEn,
    this.calificacion,
  });

  final String uid;
  final String nombre;
  final String estado; // 'aceptado', 'terminado', 'confirmado'
  final DateTime aceptadoEn;
  final DateTime? terminadoEn;
  final double? calificacion;
}

class Favor {
  const Favor({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.tamano,
    required this.estado,
    required this.cuposTotales,
    required this.cuposTomados,
    required this.solicitanteId,
    required this.solicitanteNombre,
    required this.solicitanteTelefono,
    required this.cuadraNombre,
    required this.ubicacionAproximada,
    this.ubicacionExacta,
    required this.creadoEn,
    required this.venceEn,
    required this.monedasRecompensa,
    required this.xpRecompensa,
    this.participantes = const [],
  });

  final String id;
  final String titulo;
  final String descripcion;
  final CategoriaFavor categoria;
  final TamanoFavor tamano;
  final EstadoFavor estado;
  final int cuposTotales;
  final int cuposTomados;
  final String solicitanteId;
  final String solicitanteNombre;
  final String solicitanteTelefono;
  final String cuadraNombre;
  final String ubicacionAproximada;
  final String? ubicacionExacta;
  final DateTime creadoEn;
  final DateTime venceEn;
  final int monedasRecompensa;
  final int xpRecompensa;
  final List<ParticipanteFavor> participantes;

  bool get tieneCupo => cuposTomados < cuposTotales && estado == EstadoFavor.abierto;
  int get cuposDisponibles => cuposTotales - cuposTomados;

  Favor copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    CategoriaFavor? categoria,
    TamanoFavor? tamano,
    EstadoFavor? estado,
    int? cuposTotales,
    int? cuposTomados,
    String? solicitanteId,
    String? solicitanteNombre,
    String? solicitanteTelefono,
    String? cuadraNombre,
    String? ubicacionAproximada,
    String? ubicacionExacta,
    DateTime? creadoEn,
    DateTime? venceEn,
    int? monedasRecompensa,
    int? xpRecompensa,
    List<ParticipanteFavor>? participantes,
  }) {
    return Favor(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      tamano: tamano ?? this.tamano,
      estado: estado ?? this.estado,
      cuposTotales: cuposTotales ?? this.cuposTotales,
      cuposTomados: cuposTomados ?? this.cuposTomados,
      solicitanteId: solicitanteId ?? this.solicitanteId,
      solicitanteNombre: solicitanteNombre ?? this.solicitanteNombre,
      solicitanteTelefono: solicitanteTelefono ?? this.solicitanteTelefono,
      cuadraNombre: cuadraNombre ?? this.cuadraNombre,
      ubicacionAproximada: ubicacionAproximada ?? this.ubicacionAproximada,
      ubicacionExacta: ubicacionExacta ?? this.ubicacionExacta,
      creadoEn: creadoEn ?? this.creadoEn,
      venceEn: venceEn ?? this.venceEn,
      monedasRecompensa: monedasRecompensa ?? this.monedasRecompensa,
      xpRecompensa: xpRecompensa ?? this.xpRecompensa,
      participantes: participantes ?? this.participantes,
    );
  }
}

