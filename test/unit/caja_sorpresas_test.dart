import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/mascota/domain/entities/item_mascota.dart';
import 'package:hackaton_hello_world/features/mascota/domain/entities/mascota.dart';
import 'package:hackaton_hello_world/features/mascota/domain/services/caja_sorpresas_service.dart';

class _FakeRandom implements math.Random {
  _FakeRandom(this.fixedValue);
  final double fixedValue;

  @override
  double nextDouble() => fixedValue;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

void main() {
  group('CajaSorpresasService', () {
    test('Primera caja es gratuita y desactiva la gratuidad posterior', () {
      final service = CajaSorpresasService(random: _FakeRandom(0.1)); // 0.1 da sombrero comun
      final mascota = Mascota.inicial();
      expect(mascota.primeraCajaGratis, isTrue);

      final resultado = service.abrirCaja(mascota: mascota, fichasDisponibles: 0);

      expect(resultado.fichasCobradas, 0);
      expect(resultado.esNuevo, isTrue);
      expect(resultado.mascotaActualizada.primeraCajaGratis, isFalse);
      expect(resultado.mascotaActualizada.cajasAbiertasTotal, 1);
    });

    test('Lanza StateError si el usuario no tiene saldo suficiente en caja paga', () {
      final service = CajaSorpresasService();
      const mascota = Mascota(nombre: 'Mi Cuy', primeraCajaGratis: false);

      expect(
        () => service.abrirCaja(mascota: mascota, fichasDisponibles: 20),
        throwsA(isA<StateError>()),
      );
    });

    test('Garantia de Pity: la caja 21 otorga el legendario mugiwara garantizado', () {
      final service = CajaSorpresasService(random: _FakeRandom(0.01)); // Roll que daria comun normalmente
      const mascotaEnPity = Mascota(
        nombre: 'Mi Cuy',
        pityCount: 20, // 20 cajas previas sin legendario
        primeraCajaGratis: false,
      );

      final resultado = service.abrirCaja(mascota: mascotaEnPity, fichasDisponibles: 30);

      expect(resultado.esGarantizado, isTrue);
      expect(resultado.item.id, 'mugiwara');
      expect(resultado.item.rareza, RarezaItem.legendario);
      expect(resultado.mascotaActualizada.pityCount, 0); // Reinicia pity
    });

    test('Reembolso de 15 fichas al obtener un item duplicado', () {
      // 0.05 siempre cae en sombrero (0.0 a 0.40)
      final service = CajaSorpresasService(random: _FakeRandom(0.05));
      const mascotaConSombrero = Mascota(
        nombre: 'Mi Cuy',
        itemsDesbloqueados: ['sombrero'],
        primeraCajaGratis: false,
      );

      final resultado = service.abrirCaja(mascota: mascotaConSombrero, fichasDisponibles: 30);

      expect(resultado.item.id, 'sombrero');
      expect(resultado.esNuevo, isFalse);
      expect(resultado.fichasDevueltas, 15);
      expect(resultado.mascotaActualizada.itemsDesbloqueados.length, 1);
    });

    test('Incorporacion de nuevo item y actualizacion de inventario', () {
      final service = CajaSorpresasService(random: _FakeRandom(0.05)); // Da sombrero
      const mascotaSinItems = Mascota(
        nombre: 'Mi Cuy',
        itemsDesbloqueados: [],
        primeraCajaGratis: false,
      );

      final resultado = service.abrirCaja(mascota: mascotaSinItems, fichasDisponibles: 30);

      expect(resultado.esNuevo, isTrue);
      expect(resultado.fichasDevueltas, 0);
      expect(resultado.mascotaActualizada.itemsDesbloqueados, contains('sombrero'));
    });
  });
}
