import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/comunidad/data/mocks/mock_comunidad_repository.dart';
import 'package:hackaton_hello_world/features/comunidad/domain/entities/vecino_ranking.dart';
import 'package:hackaton_hello_world/features/comunidad/domain/repositories/comunidad_repository.dart';
import 'package:hackaton_hello_world/features/comunidad/presentation/pages/comunidad_page.dart';
import 'package:hackaton_hello_world/features/comunidad/presentation/pages/vecino_detalle_page.dart';
import 'package:hackaton_hello_world/home/user_profile.dart';
import 'package:provider/provider.dart';

void main() {
  group('Ranking de Vecinos y Perfiles Enriquecidos (Ate)', () {
    late MockComunidadRepository repo;

    setUp(() {
      repo = MockComunidadRepository(
        usuarioActualId: 'usr_actual',
        usuarioActualNombre: 'Carlos Mendoza',
      );
    });

    test('obtenerRanking devuelve vecinos simulados en Ate ordenados por XP', () async {
      final ranking = await repo.obtenerRanking(ambito: 'distrito');
      expect(ranking, isNotEmpty);
      expect(ranking.first.nombre, equals('Roberto Huamán'));
      expect(ranking.first.posicion, equals(1));
      expect(ranking.first.distrito, equals('Ate'));
      expect(ranking.first.xpPeriodo, greaterThanOrEqualTo(ranking[1].xpPeriodo));
      expect(ranking.any((v) => v.esUsuarioActual), isTrue);
    });

    test('obtenerVecino recupera la ficha completa con insignias y bio', () async {
      final vecino = await repo.obtenerVecino('usr_roberto');
      expect(vecino, isNotNull);
      expect(vecino!.nombre, equals('Roberto Huamán'));
      expect(vecino.distrito, equals('Ate'));
      expect(vecino.bio, contains('defensa civil'));
      expect(vecino.insignias, contains('Guardián del barrio'));
      expect(vecino.favoresCompletados, equals(34));
      expect(vecino.reconocimientos, equals(26));
    });

    test('nominarBuenVecino incrementa los reconocimientos del vecino', () async {
      final antes = await repo.obtenerVecino('usr_roberto');
      final votosAntes = antes!.reconocimientos;

      await repo.nominarBuenVecino('usr_roberto', 'Excelente apoyo en la brigada');

      final despues = await repo.obtenerVecino('usr_roberto');
      expect(despues!.reconocimientos, equals(votosAntes + 1));
    });

    test('UserProfile maneja información enriquecida de comunidad', () {
      final profile = UserProfile(
        name: 'Roberto Huamán',
        phoneNumber: '+51987111001',
        role: 'Coordinador de Defensa Civil',
        bio: 'Coordino la brigada del barrio.',
        department: 'Lima',
        province: 'Lima',
        district: 'Ate',
        xp: 1280,
        weeklyXp: 380,
        stars: 48,
        favors: 34,
        tools: 6,
        petHunger: 0.0,
        badges: const ['Guardián del barrio', 'Líder comunitario'],
        favoresCompletados: 34,
        eventosAsistidos: 21,
        reconocimientos: 26,
        rachaSemanal: 8,
      );

      expect(profile.level, equals(12));
      expect(profile.xpEnNivelActual, equals(80));
      expect(profile.badges.length, equals(2));
      expect(profile.district, equals('Ate'));

      final map = profile.toMap();
      expect(map['weeklyXp'], equals(380));
      expect(map['badges'], contains('Guardián del barrio'));
      expect(map['district'], equals('Ate'));
      expect(map['stats'], isA<Map>());
    });

    testWidgets('VecinosTab muestra cabecera de distrito Ate y lista de vecinos', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<ComunidadRepository>.value(
            value: repo,
            child: const ComunidadPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navega a la pestaña 'Vecinos'
      await tester.tap(find.text('Vecinos'));
      await tester.pumpAndSettle();

      expect(find.text('Tabla de Vecinos'), findsOneWidget);
      expect(find.text('Ate'), findsWidgets);
      expect(find.text('Buen Vecino de la Semana'), findsOneWidget);
      expect(find.text('Roberto Huamán'), findsOneWidget);
      expect(find.text('Hilda Quispe'), findsOneWidget);
    });

    testWidgets('Tocar un vecino abre VecinoDetallePage con información enriquecida', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<ComunidadRepository>.value(
            value: repo,
            child: const ComunidadPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vecinos'));
      await tester.pumpAndSettle();

      // Toca en la fila de Roberto Huamán
      await tester.tap(find.text('Roberto Huamán'));
      await tester.pumpAndSettle();

      expect(find.byType(VecinoDetallePage), findsOneWidget);
      expect(find.text('Perfil del vecino'), findsOneWidget);
      expect(find.text('Roberto Huamán'), findsWidgets);
      expect(find.text('Sobre mí'), findsOneWidget);
      expect(find.text('Insignias'), findsOneWidget);
      expect(find.text('Guardián del barrio'), findsOneWidget);
      expect(find.text('Reconocer a este vecino'), findsOneWidget);
    });
  });
}
