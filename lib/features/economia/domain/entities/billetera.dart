import 'nivel_xp.dart';

/// Estado financiero y de reputacion comunitaria del usuario.
class Billetera {
  const Billetera({
    required this.fichas,
    required this.xp,
    this.estrellas = 0,
    this.rachaSemanal = 0,
  });

  final int fichas;
  final int xp;
  final int estrellas;
  final int rachaSemanal;

  int get nivel => NivelXp.calcularNivel(xp);
  int get xpEnNivel => NivelXp.xpEnNivelActual(xp);
  int get xpParaSiguiente => NivelXp.xpRestanteParaSiguienteNivel(xp);
  double get progresoNivel => NivelXp.progresoNivel(xp);
  bool get mascotaDesbloqueada => NivelXp.mascotaDesbloqueada(xp);

  Billetera copyWith({
    int? fichas,
    int? xp,
    int? estrellas,
    int? rachaSemanal,
  }) {
    return Billetera(
      fichas: fichas ?? this.fichas,
      xp: xp ?? this.xp,
      estrellas: estrellas ?? this.estrellas,
      rachaSemanal: rachaSemanal ?? this.rachaSemanal,
    );
  }

  factory Billetera.inicial() => const Billetera(fichas: 0, xp: 0);

  factory Billetera.fromMap(Map<String, dynamic> data) {
    return Billetera(
      fichas: (data['fichas'] as num?)?.toInt() ?? (data['monedas'] as num?)?.toInt() ?? 0,
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      estrellas: (data['stars'] as num?)?.toInt() ?? (data['estrellas'] as num?)?.toInt() ?? 0,
      rachaSemanal: (data['rachaSemanal'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'fichas': fichas,
    'xp': xp,
    'stars': estrellas,
    'rachaSemanal': rachaSemanal,
  };
}
