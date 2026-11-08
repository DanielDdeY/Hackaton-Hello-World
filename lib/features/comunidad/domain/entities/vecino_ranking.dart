enum TendenciaRanking { sube, baja, igual }

class VecinoRanking {
  const VecinoRanking({
    required this.uid,
    required this.nombre,
    required this.iniciales,
    required this.distrito,
    required this.xpPeriodo,
    required this.posicion,
    required this.nivel,
    this.esUsuarioActual = false,
    this.bio = '',
    this.insignias = const [],
    this.favoresCompletados = 0,
    this.estrellas = 0,
    this.eventosAsistidos = 0,
    this.reconocimientos = 0,
    this.rachaSemanal = 0,
    this.tendencia = TendenciaRanking.igual,
    this.xpTotal = 0,
  });

  final String uid;
  final String nombre;
  final String iniciales;
  final String distrito;
  final int xpPeriodo;
  final int posicion;
  final int nivel;
  final bool esUsuarioActual;
  final String bio;
  final List<String> insignias;
  final int favoresCompletados;
  final int estrellas;
  final int eventosAsistidos;
  final int reconocimientos;
  final int rachaSemanal;
  final TendenciaRanking tendencia;
  final int xpTotal;

  VecinoRanking copyWith({
    String? uid,
    String? nombre,
    String? iniciales,
    String? distrito,
    int? xpPeriodo,
    int? posicion,
    int? nivel,
    bool? esUsuarioActual,
    String? bio,
    List<String>? insignias,
    int? favoresCompletados,
    int? estrellas,
    int? eventosAsistidos,
    int? reconocimientos,
    int? rachaSemanal,
    TendenciaRanking? tendencia,
    int? xpTotal,
  }) => VecinoRanking(
    uid: uid ?? this.uid,
    nombre: nombre ?? this.nombre,
    iniciales: iniciales ?? this.iniciales,
    distrito: distrito ?? this.distrito,
    xpPeriodo: xpPeriodo ?? this.xpPeriodo,
    posicion: posicion ?? this.posicion,
    nivel: nivel ?? this.nivel,
    esUsuarioActual: esUsuarioActual ?? this.esUsuarioActual,
    bio: bio ?? this.bio,
    insignias: insignias ?? this.insignias,
    favoresCompletados: favoresCompletados ?? this.favoresCompletados,
    estrellas: estrellas ?? this.estrellas,
    eventosAsistidos: eventosAsistidos ?? this.eventosAsistidos,
    reconocimientos: reconocimientos ?? this.reconocimientos,
    rachaSemanal: rachaSemanal ?? this.rachaSemanal,
    tendencia: tendencia ?? this.tendencia,
    xpTotal: xpTotal ?? this.xpTotal,
  );

  static TendenciaRanking tendenciaDesde(Object? valor) {
    return switch (valor) {
      'sube' => TendenciaRanking.sube,
      'baja' => TendenciaRanking.baja,
      _ => TendenciaRanking.igual,
    };
  }
}

class VecinoPerfil {
  const VecinoPerfil({
    required this.uid,
    required this.nombre,
    required this.iniciales,
    required this.rol,
    required this.bio,
    required this.distrito,
    required this.provincia,
    required this.departamento,
    required this.xpTotal,
    required this.xpPeriodo,
    required this.nivel,
    required this.estrellas,
    required this.favoresCompletados,
    required this.eventosAsistidos,
    required this.reconocimientos,
    required this.rachaSemanal,
    required this.insignias,
    required this.posicion,
    required this.esUsuarioActual,
    this.tendencia = TendenciaRanking.igual,
  });

  final String uid;
  final String nombre;
  final String iniciales;
  final String rol;
  final String bio;
  final String distrito;
  final String provincia;
  final String departamento;
  final int xpTotal;
  final int xpPeriodo;
  final int nivel;
  final int estrellas;
  final int favoresCompletados;
  final int eventosAsistidos;
  final int reconocimientos;
  final int rachaSemanal;
  final List<String> insignias;
  final int posicion;
  final bool esUsuarioActual;
  final TendenciaRanking tendencia;

  String get zona => {distrito, provincia, departamento}
      .where((value) => value.trim().isNotEmpty)
      .join(', ');

  factory VecinoPerfil.desdeRanking(VecinoRanking vecino) => VecinoPerfil(
    uid: vecino.uid,
    nombre: vecino.nombre,
    iniciales: vecino.iniciales,
    rol: 'Vecino',
    bio: vecino.bio,
    distrito: vecino.distrito,
    provincia: '',
    departamento: '',
    xpTotal: vecino.xpTotal,
    xpPeriodo: vecino.xpPeriodo,
    nivel: vecino.nivel,
    estrellas: vecino.estrellas,
    favoresCompletados: vecino.favoresCompletados,
    eventosAsistidos: vecino.eventosAsistidos,
    reconocimientos: vecino.reconocimientos,
    rachaSemanal: vecino.rachaSemanal,
    insignias: vecino.insignias,
    posicion: vecino.posicion,
    esUsuarioActual: vecino.esUsuarioActual,
    tendencia: vecino.tendencia,
  );
}

class BuenVecinoSemana {
  const BuenVecinoSemana({
    required this.uid,
    required this.nombre,
    required this.iniciales,
    required this.distrito,
    required this.motivo,
    required this.votosReconocimiento,
  });

  final String uid;
  final String nombre;
  final String iniciales;
  final String distrito;
  final String motivo;
  final int votosReconocimiento;
}

class Reconocimiento {
  const Reconocimiento({
    required this.id,
    required this.destinoUid,
    required this.destinoNombre,
    required this.motivo,
    required this.fecha,
  });

  final String id;
  final String destinoUid;
  final String destinoNombre;
  final String motivo;
  final DateTime fecha;
}
