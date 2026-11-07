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

    test('agregarFavor inserta un nuevo favor en el repositorio', () async {
      final nuevoFavor = Favor(
        id: 'fav_nuevo_test',
        titulo: 'Ayuda con víveres',
        descripcion: 'Traslado de bolsas del mercado',
        categoria: CategoriaFavor.compras,
        tamano: TamanoFavor.medio,
        estado: EstadoFavor.abierto,
        cuposTotales: 2,
        cuposTomados: 0,
        solicitanteId: 'usr_actual',
        solicitanteNombre: 'Tú',
        solicitanteTelefono: '999888777',
        cuadraNombre: 'Cdra 3',
        ubicacionAproximada: 'A 50 metros',
        creadoEn: DateTime.now(),
        venceEn: DateTime.now().add(const Duration(days: 1)),
        monedasRecompensa: 15,
        xpRecompensa: 30,
      );

      await repo.agregarFavor(nuevoFavor);
      final favorObtenido = await repo.obtenerFavorPorId('fav_nuevo_test');
      expect(favorObtenido.id, equals('fav_nuevo_test'));
      expect(favorObtenido.titulo, equals('Ayuda con víveres'));
    });

    test('reportarContenido se ejecuta sin excepciones', () async {
      expect(
        () => repo.reportarContenido('favor', 'fav_01', 'Información falsa'),
        returnsNormally,
      );
    });

    test('confirmarYCalificar cambia el estado a completado con calificacion', () async {
      await repo.confirmarYCalificar('fav_04', 5.0);
      final favor = await repo.obtenerFavorPorId('fav_04');
      expect(favor.estado, equals(EstadoFavor.completado));
      expect(favor.participantes.first.calificacion, equals(5.0));
    });

    test('verificarAsistencia marca asistenciaVerificada en el evento', () async {
      await repo.verificarAsistencia('evt_01', '1234');
      final eventos = await repo.obtenerEventos();
      final evento = eventos.firstWhere((e) => e.id == 'evt_01');
      expect(evento.asistenciaVerificada, isTrue);
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

