class VecinoRanking {
  const VecinoRanking({
    required this.uid,
    required this.nombre,
    required this.iniciales,
    required this.cuadraNombre,
    required this.xpPeriodo,
    required this.posicion,
    required this.nivel,
    this.esUsuarioActual = false,
  });

  final String uid;
  final String nombre;
  final String iniciales;
  final String cuadraNombre;
  final int xpPeriodo;
  final int posicion;
  final int nivel;
  final bool esUsuarioActual;
}

class BuenVecinoSemana {
  const BuenVecinoSemana({
    required this.uid,
    required this.nombre,
    required this.iniciales,
    required this.cuadraNombre,
    required this.motivo,
    required this.votosReconocimiento,
  });

  final String uid;
  final String nombre;
  final String iniciales;
  final String cuadraNombre;
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

