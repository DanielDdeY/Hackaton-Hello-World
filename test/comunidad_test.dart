import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/comunidad/data/mocks/mock_comunidad_repository.dart';
import 'package:hackaton_hello_world/features/comunidad/domain/entities/evento_comunitario.dart';
import 'package:hackaton_hello_world/features/comunidad/domain/entities/favor.dart';
import 'package:hackaton_hello_world/features/comunidad/presentation/pages/comunidad_page.dart';
import 'package:provider/provider.dart';

void main() {
  group('Módulo de Comunidad - Pruebas de Repositorio Mock', () {
    late MockComunidadRepository repo;

    setUp(() {
      repo = MockComunidadRepository();
    });

    test('obtenerResumenHoy retorna estadísticas y favores cercanos', () async {
      final resumen = await repo.obtenerResumenHoy();
      expect(resumen.estadisticasCuadra.porcentajeMochilaPreparada, greaterThan(0));
      expect(resumen.favoresCercanos, isNotEmpty);
    });

    test('aceptarFavor descuenta cupos y actualiza estado', () async {
      final favoresIniciales = await repo.obtenerFavores();
      final favorDisponible = favoresIniciales.firstWhere((f) => f.tieneCupo);

      final cuposAntes = favorDisponible.cuposTomados;
      await repo.aceptarFavor(favorDisponible.id);

      final favorActualizado = await repo.obtenerFavorPorId(favorDisponible.id);
      expect(favorActualizado.cuposTomados, equals(cuposAntes + 1));
    });

    test('responderEvento actualiza la intención de asistencia', () async {
      final eventos = await repo.obtenerEventos();
      final evento = eventos.first;

      await repo.responderEvento(evento.id, RespuestaEvento.voy);

      final eventosActualizados = await repo.obtenerEventos();
      final actualizado = eventosActualizados.firstWhere((e) => e.id == evento.id);
      expect(actualizado.miRespuesta, equals(RespuestaEvento.voy));
    });
  });

  group('Módulo de Comunidad - Pruebas de Interfaz UI', () {
    testWidgets('ComunidadPage renderiza las 4 pestañas superiores', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<MockComunidadRepository>(
            create: (_) => MockComunidadRepository(),
            child: const ComunidadPage(),
          ),
        ),
      );

      // Permite que los futuros y microtareas del TabController se procesen
      await tester.pumpAndSettle();

      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Favores'), findsOneWidget);
      expect(find.text('Eventos'), findsOneWidget);
      expect(find.text('Vecinos'), findsOneWidget);
    });
  });
}
