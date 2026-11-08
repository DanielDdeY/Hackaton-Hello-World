import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hackaton_hello_world/core/theme/app_theme.dart';
import 'package:hackaton_hello_world/features/comunidad/data/mocks/mock_comunidad_repository.dart';
import 'package:hackaton_hello_world/features/comunidad/presentation/controllers/comunidad_controller.dart';
import 'package:hackaton_hello_world/features/comunidad/presentation/tabs/vecinos_tab.dart';
import 'package:hackaton_hello_world/features/economy/domain/models/app_user.dart';
import 'package:hackaton_hello_world/features/economy/domain/repositories/user_repository.dart';

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository(this.topThreeStream);

  final Stream<List<AppUser>> topThreeStream;
  final requestedDistricts = <String>[];
  int topThreeRequests = 0;

  @override
  Future<AppUser> ensureUser({required String uid, String name = 'Vecino'}) {
    throw UnimplementedError();
  }

  @override
  Stream<List<AppUser>> watchMonthlyLeaderboard({
    required String district,
    int limit = 50,
  }) {
    requestedDistricts.add(district);
    return topThreeStream;
  }

  @override
  Stream<List<AppUser>> watchTopThreeOfMonth({required String district}) {
    topThreeRequests++;
    return topThreeStream;
  }

  @override
  Stream<AppUser> watchUserStats(String uid) => const Stream.empty();
}

Widget _wrapWithApp(UserRepository repository, {VoidCallback? onRetry}) {
  return Provider<UserRepository?>.value(
    value: repository,
    child: MaterialApp(
      theme: createAppTheme(),
      home: Scaffold(
        body: TopThreeMonthlyCard(
          district: 'Ate',
          currentUid: 'u1',
          onRetry: onRetry,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Vecinos conserva una consulta al reconstruir la vista', (
    tester,
  ) async {
    final stream = StreamController<List<AppUser>>();
    final users = _FakeUserRepository(stream.stream);
    final controller = ComunidadController(
      repository: MockComunidadRepository(),
    );
    addTearDown(stream.close);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<UserRepository?>.value(value: users),
          ChangeNotifierProvider<ComunidadController>.value(value: controller),
        ],
        child: const MaterialApp(home: Scaffold(body: VecinosTab())),
      ),
    );
    await tester.pump();
    stream.add(const [
      AppUser(
        uid: 'vecino1',
        name: 'Vecino real',
        district: 'Ate',
        currentPeriod: '2026-11',
        monthlyXp: 10,
        rankingPeriod: '2026-11',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Vecino real'), findsWidgets);
    controller.limpiarError();
    await tester.pumpAndSettle();
    expect(find.text('Vecino real'), findsWidgets);
    expect(users.requestedDistricts, [controller.distritoRanking]);
    expect(users.topThreeRequests, 0);
  });

  testWidgets('TopThreeMonthlyCard muestra estado de carga', (tester) async {
    final controller = StreamController<List<AppUser>>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      _wrapWithApp(_FakeUserRepository(controller.stream)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Top 3 del Mes del Barrio'), findsOneWidget);
  });

  testWidgets('TopThreeMonthlyCard muestra estado de error y reintento', (
    tester,
  ) async {
    var retried = false;
    final stream = Stream<List<AppUser>>.error(
      const UserFailure(UserFailureReason.networkUnavailable),
    );

    await tester.pumpWidget(
      _wrapWithApp(_FakeUserRepository(stream), onRetry: () => retried = true),
    );
    await tester.pump();

    expect(
      find.text('No se pudo cargar el Top 3 del mes del barrio.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);
  });

  testWidgets('TopThreeMonthlyCard muestra mensaje cuando está vacío', (
    tester,
  ) async {
    final stream = Stream<List<AppUser>>.value(const []);

    await tester.pumpWidget(_wrapWithApp(_FakeUserRepository(stream)));
    await tester.pump();

    expect(
      find.textContaining('Aún no hay puntos este mes en el barrio'),
      findsOneWidget,
    );
  });

  testWidgets('TopThreeMonthlyCard muestra de 1 a 3 vecinos en el podio', (
    tester,
  ) async {
    final users = [
      const AppUser(
        uid: 'u1',
        name: 'Ana Torres',
        district: 'Ate',
        currentPeriod: '2026-11',
        xpTotal: 350,
        monthlyXp: 120,
        rankingPeriod: '2026-11',
      ),
      const AppUser(
        uid: 'u2',
        name: 'Luis Gómez',
        district: 'Ate',
        currentPeriod: '2026-11',
        xpTotal: 210,
        monthlyXp: 95,
        rankingPeriod: '2026-11',
      ),
      const AppUser(
        uid: 'u3',
        name: 'Rosa Díaz',
        district: 'Ate',
        currentPeriod: '2026-11',
        xpTotal: 140,
        monthlyXp: 60,
        rankingPeriod: '2026-11',
      ),
    ];

    await tester.pumpWidget(
      _wrapWithApp(_FakeUserRepository(Stream.value(users))),
    );
    await tester.pump();

    expect(find.text('1°'), findsOneWidget);
    expect(find.text('Ana Torres'), findsOneWidget);
    expect(find.text('120 XP'), findsOneWidget);
    expect(find.text('2°'), findsOneWidget);
    expect(find.text('Luis Gómez'), findsOneWidget);
    expect(find.text('3°'), findsOneWidget);
    expect(find.text('Rosa Díaz'), findsOneWidget);
  });
}
