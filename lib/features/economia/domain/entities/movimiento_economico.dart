enum TipoMovimiento {
  ingreso,
  egreso,
}

enum ConceptoMovimiento {
  recompensaFavor,
  subidaNivel,
  compraCaja,
  eventoComunitario,
  reconocimiento,
  bonoRacha,
  ajuste,
}

/// Registro historico de una transaccion de fichas o puntos de experiencia.
class MovimientoEconomico {
  const MovimientoEconomico({
    required this.id,
    required this.uid,
    required this.tipo,
    required this.concepto,
    required this.fichas,
    required this.xp,
    required this.descripcion,
    required this.fecha,
    this.referenciaId,
  });

  final String id;
  final String uid;
  final TipoMovimiento tipo;
  final ConceptoMovimiento concepto;
  final int fichas;
  final int xp;
  final String descripcion;
  final DateTime fecha;
  final String? referenciaId;

  Map<String, dynamic> toMap() => {
    'id': id,
    'uid': uid,
    'tipo': tipo.name,
    'concepto': concepto.name,
    'fichas': fichas,
    'xp': xp,
    'descripcion': descripcion,
    'fecha': fecha.toIso8601String(),
    if (referenciaId != null) 'referenciaId': referenciaId,
  };

  factory MovimientoEconomico.fromMap(Map<String, dynamic> data) {
    return MovimientoEconomico(
      id: data['id'] as String? ?? '',
      uid: data['uid'] as String? ?? '',
      tipo: TipoMovimiento.values.firstWhere(
        (t) => t.name == data['tipo'],
        orElse: () => TipoMovimiento.ingreso,
      ),
      concepto: ConceptoMovimiento.values.firstWhere(
        (c) => c.name == data['concepto'],
        orElse: () => ConceptoMovimiento.ajuste,
      ),
      fichas: (data['fichas'] as num?)?.toInt() ?? 0,
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      descripcion: data['descripcion'] as String? ?? '',
      fecha: DateTime.tryParse(data['fecha'] as String? ?? '') ?? DateTime.now(),
      referenciaId: data['referenciaId'] as String?,
    );
  }
}

