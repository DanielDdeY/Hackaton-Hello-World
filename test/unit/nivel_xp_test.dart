import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/economia/domain/entities/nivel_xp.dart';

void main() {
  group('NivelXp - Progresion y Curva Economica', () {
    test('Calculo acumulado para niveles clave', () {
      expect(NivelXp.xpAcumuladoParaNivel(0), 0);
      expect(NivelXp.xpAcumuladoParaNivel(1), 100);
      expect(NivelXp.xpAcumuladoParaNivel(2), 210); // 100 + 110
      expect(NivelXp.xpAcumuladoParaNivel(3), 330); // 100 + 110 + 120
      expect(NivelXp.xpAcumuladoParaNivel(4), 460); // 100 + 110 + 120 + 130
    });

    test('Calculo del nivel segun experiencia total', () {
      expect(NivelXp.calcularNivel(0), 0);
      expect(NivelXp.calcularNivel(50), 0);
      expect(NivelXp.calcularNivel(99), 0);
      expect(NivelXp.calcularNivel(100), 1);
      expect(NivelXp.calcularNivel(150), 1);
      expect(NivelXp.calcularNivel(209), 1);
      expect(NivelXp.calcularNivel(210), 2);
      expect(NivelXp.calcularNivel(329), 2);
      expect(NivelXp.calcularNivel(330), 3);
    });

    test('Calculo de experiencia en nivel actual y restante', () {
      expect(NivelXp.xpEnNivelActual(150), 50);
      expect(NivelXp.xpRestanteParaSiguienteNivel(150), 60); // Nivel 2 en 210 -> 210 - 150 = 60

      expect(NivelXp.xpEnNivelActual(210), 0);
      expect(NivelXp.xpRestanteParaSiguienteNivel(210), 120); // Nivel 3 en 330 -> 330 - 210 = 120
    });

    test('Progreso porcentual en el nivel actual', () {
      expect(NivelXp.progresoNivel(100), 0.0);
      expect(NivelXp.progresoNivel(155), closeTo(0.5, 0.01)); // 55 de 110
      expect(NivelXp.progresoNivel(210), 0.0);
    });

    test('Desbloqueo de mascota al alcanzar nivel 2 (210 XP)', () {
      expect(NivelXp.mascotaDesbloqueada(100), isFalse);
      expect(NivelXp.mascotaDesbloqueada(209), isFalse);
      expect(NivelXp.mascotaDesbloqueada(210), isTrue);
      expect(NivelXp.mascotaDesbloqueada(500), isTrue);
    });
  });
}
