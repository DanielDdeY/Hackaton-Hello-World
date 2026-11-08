import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/economia/domain/entities/billetera.dart';
import 'package:hackaton_hello_world/features/economia/domain/entities/movimiento_economico.dart';

void main() {
  group('Billetera Entity', () {
    test('Valores iniciales por defecto', () {
      final billetera = Billetera.inicial();
      expect(billetera.fichas, 0);
      expect(billetera.xp, 0);
      expect(billetera.nivel, 0);
      expect(billetera.mascotaDesbloqueada, isFalse);
    });

    test('Billetera refleja desbloqueo de mascota al nivel 2 (210 XP)', () {
      const billeteraBaja = Billetera(fichas: 50, xp: 200);
      expect(billeteraBaja.nivel, 1);
      expect(billeteraBaja.mascotaDesbloqueada, isFalse);

      const billeteraDesbloqueada = Billetera(fichas: 50, xp: 210);
      expect(billeteraDesbloqueada.nivel, 2);
      expect(billeteraDesbloqueada.mascotaDesbloqueada, isTrue);
    });

    test('Serializacion y deserializacion de mapa', () {
      final billetera = const Billetera(fichas: 35, xp: 460, estrellas: 5, rachaSemanal: 2);
      final map = billetera.toMap();
      expect(map['fichas'], 35);
      expect(map['xp'], 460);

      final cargada = Billetera.fromMap(map);
      expect(cargada.fichas, 35);
      expect(cargada.xp, 460);
      expect(cargada.nivel, 4);
    });
  });

  group('MovimientoEconomico Entity', () {
    test('Serializacion y deserializacion de movimientos', () {
      final movimiento = MovimientoEconomico(
        id: 'mov_123',
        uid: 'user_abc',
        tipo: TipoMovimiento.ingreso,
        concepto: ConceptoMovimiento.recompensaFavor,
        fichas: 15,
        xp: 30,
        descripcion: 'Ayuda con compras del mercado',
        fecha: DateTime(2026, 11, 8, 12, 0),
        referenciaId: 'favor_999',
      );

      final map = movimiento.toMap();
      expect(map['tipo'], 'ingreso');
      expect(map['concepto'], 'recompensaFavor');
      expect(map['fichas'], 15);
      expect(map['xp'], 30);
      expect(map['referenciaId'], 'favor_999');

      final reconstruido = MovimientoEconomico.fromMap(map);
      expect(reconstruido.id, 'mov_123');
      expect(reconstruido.tipo, TipoMovimiento.ingreso);
      expect(reconstruido.concepto, ConceptoMovimiento.recompensaFavor);
      expect(reconstruido.fichas, 15);
      expect(reconstruido.xp, 30);
    });
  });
}

