import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hackaton_hello_world/core/theme/app_theme.dart';
import 'package:hackaton_hello_world/features/comunidad/presentation/tabs/vecinos_tab.dart';
import 'package:hackaton_hello_world/features/economy/domain/models/app_user.dart';
import 'package:hackaton_hello_world/features/economy/domain/repositories/user_repository.dart';

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository(this.topThreeStream);

  final Stream<List<AppUser>> topThreeStream;

  @override
  Future<AppUser> ensureUser({required String uid, String name = 'Vecino'}) {
    throw UnimplementedError();
  }

  @override
  Stream<List<AppUser>> watchMonthlyLeaderboard({
    required String district,
    int limit = 50,
  }) => topThreeStream;

  @override
  Stream<List<AppUser>> watchTopThreeOfMonth({required String district}) =>
      topThreeStream;

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
