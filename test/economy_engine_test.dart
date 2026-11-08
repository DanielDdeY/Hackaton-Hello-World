import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/auth_gateway.dart';
import 'package:hackaton_hello_world/features/economy/domain/models/economy_result.dart';
import 'package:hackaton_hello_world/features/economy/domain/repositories/economy_store.dart';
import 'package:hackaton_hello_world/features/economy/domain/services/period_provider.dart';
import 'package:hackaton_hello_world/features/economy/domain/services/service_economy_engine.dart';

class _Auth implements AuthGateway {
  String? uid = 'client';
  @override
  String? get currentUid => uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Store implements EconomyStore {
  Map<String, Map<String, dynamic>> docs = {};
  Future<void> _queue = Future.value();
  bool failCommit = false;
  int commits = 0;
  int lastWriteCount = 0;
  @override
  Object get serverTimestamp => 'server-time';
  @override
  String newOperationId() => 'new-operation-0001';
  @override
  Future<T> runTransaction<T>(
    Future<T> Function(EconomyTransaction tx) action,
  ) {
    final result = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        final copy = {
          for (final e in docs.entries)
            e.key: Map<String, dynamic>.from(e.value),
        };
        final tx = _Tx(copy);
        final value = await action(tx);
        if (failCommit) {
          throw const EconomyFailure(EconomyFailureReason.networkUnavailable);
        }
        docs = copy;
        lastWriteCount = tx.writes;
        if (tx.writes > 0) commits++;
        result.complete(value);
      } catch (e, st) {
        result.completeError(e, st);
      }
    });
    return result.future;
  }
}

class _Tx implements EconomyTransaction {
  _Tx(this.docs);
  final Map<String, Map<String, dynamic>> docs;
  int writes = 0;
  @override
  Future<Map<String, dynamic>?> get(String path) async {
    if (writes > 0) throw StateError('Read after write');
    final value = docs[path];
    return value == null ? null : Map.of(value);
  }

  @override
  void create(String path, Map<String, dynamic> data) {
    if (docs.containsKey(path)) throw StateError('Already exists');
    writes++;
    docs[path] = Map.of(data);
  }

  @override
  void update(String path, Map<String, dynamic> data) {
    final previous = docs[path];
    if (previous == null) throw StateError('Missing document');
    writes++;
    docs[path] = {...previous, ...data};
  }

  @override
  void increment(String path, String field, num amount) {
    update(path, {field: (docs[path]![field] as num) + amount});
  }
}

Matcher failure(EconomyFailureReason reason) =>
    throwsA(isA<EconomyFailure>().having((e) => e.reason, 'reason', reason));

void main() {
  late _Store store;
  late _Auth auth;
  late FakePeriodProvider periods;
  late ServiceEconomyEngine engine;
  Map<String, dynamic> user(int xp) => {
    'profileVersion': 1,
    'xp': xp,
    'monthlyXp': 10,
    'rankingPeriod': '2026-11',
    'averageStars': 0.0,
    'reviewCount': 0,
    'name': 'Vecino',
    'districtKey': 'ate',
  };
  setUp(() {
    store = _Store()
      ..docs = {
        'posts/service': {
          'category': 'service',
          'status': 'active',
          'authorId': 'provider',
        },
        'users/client': user(100),
        'users/provider': user(200),
        'users/client/private/account': {'availableCoins': 77},
        'users/provider/private/account': {'availableCoins': 88},
      };
    auth = _Auth();
    periods = FakePeriodProvider('2026-11');
    engine = ServiceEconomyEngine(
      store: store,
      auth: auth,
      periods: periods,
      writesEnabled: () => true,
    );
  });
  Future<EconomyResult> confirm([
    String op = 'operation-00000001',
    int rating = 4,
  ]) =>
      engine.confirmService(postId: 'service', rating: rating, operationId: op);

  test('Confirmar un favor otorga XP y monedas una sola vez', () async {
    store.docs['posts/favor'] = {
      'category': 'help',
      'status': 'active',
      'authorId': 'client',
    };
    const offer = 'posts/favor/helpOffers/provider';
    store.docs[offer] = {'offeredAt': 'earlier'};
    await engine.confirmFavor(postId: 'favor', helperUid: 'provider');
    expect(store.docs[offer]!['confirmedAt'], 'server-time');
    expect(store.docs['users/provider']!['xp'], 210);
    expect(store.docs['users/provider/private/account']!['availableCoins'], 93);
    expect(store.docs['users/provider/movimientos/favor_completed_favor'], isNotNull);
    await engine.confirmFavor(postId: 'favor', helperUid: 'provider');
    expect(store.commits, 1);
  });

  test('Confirmar un favor con recompensa del autor solo confirma la ayuda', () async {
    store.docs['posts/favor'] = {
      'category': 'help',
      'status': 'active',
      'authorId': 'client',
      'details': {'hasReward': true},
    };
    const offer = 'posts/favor/helpOffers/provider';
    store.docs[offer] = {'offeredAt': 'earlier'};
    await engine.confirmFavor(postId: 'favor', helperUid: 'provider');
    expect(store.docs[offer]!['confirmedAt'], 'server-time');
    expect(store.docs['users/provider']!['xp'], 200);
    expect(store.docs['users/provider/private/account']!['availableCoins'], 88);
    expect(store.docs['users/provider/movimientos/favor_completed_favor'], isNull);
  });

  test('El bono del evento requiere Voy y se conserva entre meses', () async {
    store.docs['posts/event'] = {
      'category': 'event',
      'status': 'active',
      'authorId': 'provider',
    };
    Future<EconomyResult> claim() => engine.award(
      source: EconomySource.attendedEvent,
      sourceId: 'event',
      operationId: engine.newOperationId(),
    );
    await expectLater(claim(), failure(EconomyFailureReason.activityNotEligible));
    store.docs['posts/event/attendance/client'] = {'response': 'going'};
    expect((await claim()).alreadyApplied, isFalse);
    expect(store.docs['users/client']!['xp'], 110);
    expect(store.docs['users/client/private/account']!['availableCoins'], 80);
    periods.currentPeriod = '2026-12';
    expect((await claim()).alreadyApplied, isTrue);
    expect(store.commits, 1);
  });

  test('Premia ambos usuarios y registra dos movimientos en un solo commit', () async {
    final result = await confirm();
    expect(store.commits, 1);
    expect(store.lastWriteCount, 6);
    expect(store.docs['users/client']!['xp'], 115);
    expect(store.docs['users/provider']!['xp'], 225);
    expect(store.docs['users/client']!['monthlyXp'], 25);
    expect(store.docs['users/provider']!['monthlyXp'], 35);
    expect(store.docs['users/provider']!['averageStars'], 4);
    expect(store.docs['users/provider']!['reviewCount'], 1);
    expect(store.docs['users/client/private/account']!['availableCoins'], 77);
    expect(store.docs['users/provider/private/account']!['availableCoins'], 88);
    expect(
      store
          .docs['users/client/movimientos/${result.confirmationId}']!['deltaCoins'],
      0,
    );
    expect(
      store
          .docs['users/provider/movimientos/${result.confirmationId}']!['deltaXpTotal'],
      25,
    );
  });
  test(
    'Un fallo de commit no deja XP ni documentos aplicados a medias',
    () async {
      final before = Map.of(store.docs);
      store.failCommit = true;
      await expectLater(
        confirm(),
        failure(EconomyFailureReason.networkUnavailable),
      );
      expect(store.docs, before);
      store.failCommit = false;
      await confirm();
      expect(store.docs['users/client']!['xp'], 115);
      expect(store.commits, 1);
    },
  );
  test(
    'Dos invocaciones simultáneas con igual operación no consumen dos cupos',
    () async {
      final results = await Future.wait([confirm(), confirm()]);
      expect(results.where((r) => r.alreadyApplied).length, 1);
      expect(store.commits, 1);
      expect(store.docs['users/provider']!['reviewCount'], 1);
    },
  );
  test(
    'Dos usos distintos del mismo post, tercero rechazado, promedio correcto',
    () async {
      await confirm();
      await confirm('operation-00000002', 2);
      expect(store.docs['users/provider']!['averageStars'], 3);
      expect(store.docs['users/provider']!['reviewCount'], 2);
      expect(store.docs['users/client']!['xp'], 130);
      await expectLater(
        confirm('operation-00000003'),
        failure(EconomyFailureReason.monthlyPairLimitReached),
      );
      expect(store.commits, 2);
    },
  );
  test(
    'El límite se comparte entre publicaciones del mismo proveedor',
    () async {
      await confirm();
      await confirm('operation-00000002');
      store.docs['posts/other'] = Map.of(store.docs['posts/service']!);
      await expectLater(
        engine.confirmService(
          postId: 'other',
          rating: 5,
          operationId: 'operation-00000003',
        ),
        failure(EconomyFailureReason.monthlyPairLimitReached),
      );
    },
  );
  test('Otra pareja conserva sus propios cupos', () async {
    await confirm();
    await confirm('operation-00000002');
    store.docs['users/other'] = user(0);
    store.docs['posts/other'] = {
      'category': 'service',
      'status': 'active',
      'authorId': 'other',
    };
    await engine.confirmService(
      postId: 'other',
      rating: 5,
      operationId: 'operation-00000003',
    );
    expect(store.docs['users/other']!['xp'], 25);
  });
  test(
    'Reintentar con otra calificación o post no modifica la operación original',
    () async {
      await confirm();
      await expectLater(
        confirm('operation-00000001', 5),
        failure(EconomyFailureReason.operationConflict),
      );
      expect(store.commits, 1);
    },
  );
  test(
    'Reintento en otro mes y con post borrado devuelve el recibo original',
    () async {
      await confirm();
      periods.currentPeriod = '2026-12';
      store.docs.remove('posts/service');
      final result = await confirm();
      expect(result.alreadyApplied, true);
      expect(result.period, '2026-11');
      expect(store.commits, 1);
    },
  );
  test(
    'Mes nuevo reinicia solo el XP mensual y libera los dos cupos',
    () async {
      await confirm();
      await confirm('operation-00000002');
      periods.currentPeriod = '2026-12';
      await confirm('operation-00000003');
      expect(store.docs['users/client']!['xp'], 145);
      expect(store.docs['users/client']!['monthlyXp'], 15);
      expect(store.docs['users/provider']!['monthlyXp'], 25);
      expect(store.docs['users/client/private/account']!['availableCoins'], 77);
    },
  );
  test('Nunca retrocede un periodo futuro', () async {
    store.docs['users/provider']!['rankingPeriod'] = '2026-12';
    await expectLater(confirm(), failure(EconomyFailureReason.futurePeriod));
    expect(store.commits, 0);
  });
  test('Auto-confirmación se rechaza usando el authorId leído', () async {
    store.docs['posts/service']!['authorId'] = 'client';
    await expectLater(
      confirm(),
      failure(EconomyFailureReason.selfConfirmation),
    );
    expect(store.commits, 0);
  });
  test(
    'Usuario ausente produce error y no genera un perfil ficticio',
    () async {
      store.docs.remove('users/provider');
      await expectLater(confirm(), failure(EconomyFailureReason.userNotFound));
      expect(store.commits, 0);
    },
  );
  test('Perfil sin migrar no puede recibir recompensa', () async {
    store.docs['users/provider']!.remove('profileVersion');
    await expectLater(confirm(), failure(EconomyFailureReason.profileNotReady));
  });
  test('Servicio inactivo o de otra categoría no se premia', () async {
    store.docs['posts/service']!['status'] = 'closed';
    await expectLater(confirm(), failure(EconomyFailureReason.inactiveService));
    store.docs['posts/service']!['category'] = 'help';
    await expectLater(confirm(), failure(EconomyFailureReason.serviceNotFound));
  });
  test('Calificación obligatoria y entre 1 y 5', () async {
    await expectLater(
      confirm('operation-00000001', 0),
      failure(EconomyFailureReason.invalidRating),
    );
    await expectLater(
      confirm('operation-00000001', 6),
      failure(EconomyFailureReason.invalidRating),
    );
  });
  test(
    'Identificador de operación inválido se rechaza antes de escribir',
    () async {
      await expectLater(
        confirm('../bad'),
        failure(EconomyFailureReason.invalidOperation),
      );
    },
  );
  test(
    'No crea una sesión anónima nueva para premiar silenciosamente',
    () async {
      auth.uid = null;
      await expectLater(confirm(), failure(EconomyFailureReason.noSession));
    },
  );
  test('Simulación bloquea escrituras por defecto', () async {
    engine = ServiceEconomyEngine(store: store, auth: auth, periods: periods);
    await expectLater(
      confirm(),
      failure(EconomyFailureReason.simulationActive),
    );
    expect(store.commits, 0);
  });
  test('Fuentes sin regla definida no inventan recompensas', () {
    expect(
      () => engine.award(
        source: EconomySource.completedFavor,
        sourceId: 'favor',
        operationId: 'operation-00000001',
      ),
      failure(EconomyFailureReason.unsupportedSource),
    );
  });
  test('Bono de mochila otorga 100 XP y 50 fichas de forma idempotente', () async {
    final result = await engine.award(
      source: EconomySource.backpackVerified,
      sourceId: 'mochila',
      operationId: 'operation-00000001',
    );
    expect(result.alreadyApplied, false);
    expect(result.confirmationId, 'backpack_verified_mochila');
    expect(result.clientXp, 100);
    expect(result.coins, 50);

    expect(store.docs['users/client']!['xp'], 200);
    expect(store.docs['users/client']!['monthlyXp'], 110);
    expect(store.docs['users/client/private/account']!['availableCoins'], 127);
    final mov = store.docs['users/client/movimientos/backpack_verified_mochila']!;
    expect(mov['deltaXpTotal'], 100);
    expect(mov['deltaXpMonth'], 100);
    expect(mov['deltaCoins'], 50);
    expect(mov['type'], 'backpack_verified');

    final replay = await engine.award(
      source: EconomySource.backpackVerified,
      sourceId: 'mochila',
      operationId: 'operation-00000001',
    );
    expect(replay.alreadyApplied, true);
    expect(store.docs['users/client']!['xp'], 200);
    expect(store.docs['users/client/private/account']!['availableCoins'], 127);
  });
}
