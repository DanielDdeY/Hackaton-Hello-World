/// Calculo de niveles y progresion de experiencia segun la curva economica.
class NivelXp {
  const NivelXp._();

  static const int xpBase = 100;
  static const int xpIncremento = 10;
  static const int nivelDesbloqueoMascota = 2; // 210 XP acumulados
  static const int fichasPorSubidaNivel = 10;

  /// Experiencia requerida para avanzar desde [nivelActual] al siguiente nivel.
  static int xpParaSiguienteNivel(int nivelActual) {
    if (nivelActual < 0) return xpBase;
    return xpBase + (nivelActual * xpIncremento);
  }

  /// Total de experiencia acumulada necesaria para alcanzar [nivel].
  static int xpAcumuladoParaNivel(int nivel) {
    if (nivel <= 0) return 0;
    // Suma aritmetica: 100*n + 10*(n*(n-1)/2)
    return (xpBase * nivel) + (xpIncremento * (nivel * (nivel - 1) ~/ 2));
  }

  /// Calcula el nivel actual a partir de la experiencia total acumulada.
  static int calcularNivel(int xpTotal) {
    if (xpTotal < xpBase) return 0;
    int nivel = 0;
    while (xpTotal >= xpAcumuladoParaNivel(nivel + 1)) {
      nivel++;
    }
    return nivel;
  }

  /// Experiencia ganada dentro del nivel actual.
  static int xpEnNivelActual(int xpTotal) {
    final nivel = calcularNivel(xpTotal);
    return xpTotal - xpAcumuladoParaNivel(nivel);
  }

  /// Experiencia faltante para alcanzar el siguiente nivel.
  static int xpRestanteParaSiguienteNivel(int xpTotal) {
    final nivel = calcularNivel(xpTotal);
    return xpAcumuladoParaNivel(nivel + 1) - xpTotal;
  }

  /// Progreso porcentual (0.0 a 1.0) dentro del nivel actual hacia el siguiente.
  static double progresoNivel(int xpTotal) {
    final nivel = calcularNivel(xpTotal);
    final xpRequerido = xpParaSiguienteNivel(nivel);
    if (xpRequerido <= 0) return 1.0;
    final ganado = xpEnNivelActual(xpTotal);
    return (ganado / xpRequerido).clamp(0.0, 1.0);
  }

  /// Determina si el usuario tiene acceso a la mascota (nivel >= 2, es decir 210 XP).
  static bool mascotaDesbloqueada(int xpTotal) {
    return calcularNivel(xpTotal) >= nivelDesbloqueoMascota;
  }
}
