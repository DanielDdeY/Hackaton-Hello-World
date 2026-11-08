import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/economy/domain/models/app_user.dart';
import 'package:hackaton_hello_world/features/economy/domain/services/period_provider.dart';
import 'package:hackaton_hello_world/features/economy/data/user_initialization.dart';

void main() {
  test('El mes se calcula en Lima en ambos lados de medianoche', () {
    expect(
      SystemPeriodProvider(clock: () => DateTime.utc(2026, 11, 1, 4, 30))
          .currentPeriod,
      '2026-10',
    );
    expect(
      SystemPeriodProvider(clock: () => DateTime.utc(2026, 11, 1, 5))
          .currentPeriod,
      '2026-11',
    );
    expect(
      SystemPeriodProvider(clock: () => DateTime.utc(2027, 1, 1, 4, 59))
          .currentPeriod,
      '2026-12',
    );
  });
  test('Parsea números y conserva la fórmula de nivel existente', () {
    final user = AppUser.fromMap(
      'u',
      {
        'xp': 280.0,
        'monthlyXp': 30.0,
        'rankingPeriod': '2026-10',
        'averageStars': 4,
        'reviewCount': 2.0,
      },
      currentPeriod: '2026-11',
      privateAccount: {'availableCoins': 10.0},
    );
    expect(user.xpTotal, 280);
    expect(user.level, 2);
    expect(user.effectiveMonthlyXp, 0);
    expect(user.availableCoins, 10);
    expect(user.averageStars, 4);
    expect(user.reviewCount, 2);
    expect(user.toMap().keys, isNot(contains('monthlyXp')));
    expect(user.toMap().keys, isNot(contains('rankingPeriod')));
    expect(user.toMap().keys, isNot(contains('xp')));
  });
  test('Bono solo al crear y una segunda inicialización no lo repite', () {
    final first = UserInitialization(
      existing: null,
      account: null,
      proximity: null,
      uid: 'u',
      name: 'Ana',
      period: '2026-11',
    );
    final again = UserInitialization(
      existing: first.publicData,
      account: first.privateData,
      proximity: null,
      uid: 'u',
      name: 'Otro nombre',
      period: '2026-11',
    );
    expect(first.publicData['xp'], 20);
    expect(first.publicData['monthlyXp'], 20);
    expect(first.privateData['availableCoins'], 10);
    expect(again.publicData, first.publicData);
    expect(again.privateData, first.privateData);
  });
  test('El reinicio conserva XP permanente, monedas y reputación', () {
    final plan = UserInitialization(
      existing: {
        'xp': 350,
        'monthlyXp': 90,
        'rankingPeriod': '2026-10',
        'averageStars': 4.5,
        'reviewCount': 6,
      },
      account: {'availableCoins': 77},
      proximity: null,
      uid: 'u',
      name: 'Ana',
      period: '2026-11',
    );
    expect(plan.publicData['xp'], 350);
    expect(plan.publicData['monthlyXp'], 0);
    expect(plan.publicData['rankingPeriod'], '2026-11');
    expect(plan.privateData['availableCoins'], 77);
    expect(plan.publicData['averageStars'], 4.5);
  });
  test('Un periodo futuro nunca se reinicia ni retrocede', () {
    final plan = UserInitialization(
      existing: {'xp': 350, 'monthlyXp': 90, 'rankingPeriod': '2027-01'},
      account: null,
      proximity: null,
      uid: 'u',
      name: 'Ana',
      period: '2026-11',
    );
    expect(plan.publicData['rankingPeriod'], '2027-01');
    expect(plan.publicData['monthlyXp'], 90);
    final user = AppUser.fromMap(
      'u',
      plan.publicData,
      currentPeriod: '2026-11',
    );
    expect(user.needsReset, false);
    expect(user.effectiveMonthlyXp, 0);
    expect(user.xpTotal, 350);
  });
  test('Migra datos privados sin copiar XP semanal al ranking mensual', () {
    final plan = UserInitialization(
      existing: {
        'xp': 900,
        'weeklyXp': 600,
        'level': 9,
        'district': '  ATE ',
        'phoneNumber': '999999999',
        'email': 'demo@example.test',
        'location': 'point',
        'fcmToken': 'token',
        'communityId': 'ate',
        'availableCoins': 12,
      },
      account: null,
      proximity: null,
      uid: 'u',
      name: 'Ana',
      period: '2026-11',
    );
    expect(plan.publicData['xp'], 900);
    expect(plan.publicData['monthlyXp'], 0);
    expect(plan.publicData['weeklyXp'], 600);
    expect(plan.publicData['districtKey'], 'ate');
    expect(plan.publicData.keys, isNot(contains('phoneNumber')));
    expect(plan.publicData.keys, isNot(contains('location')));
    expect(plan.publicData.keys, isNot(contains('fcmToken')));
    expect(plan.publicData.keys, isNot(contains('level')));
    expect(plan.privateData['availableCoins'], 12);
    expect(plan.privateData['phoneNumber'], '999999999');
    expect(plan.proximityData['fcmToken'], 'token');
    expect(plan.proximityData['uid'], 'u');
  });
  test('Usuarios antiguos reciben campos nuevos sin bono retroactivo', () {
    final plan = UserInitialization(
      existing: {'name': 'Luis', 'xp': 100},
      account: null,
      proximity: null,
      uid: 'u',
      name: 'Vecino',
      period: '2026-11',
    );
    expect(plan.publicData['xp'], 100);
    expect(plan.publicData['monthlyXp'], 0);
    expect(plan.privateData['availableCoins'], 0);
    expect(plan.publicData['name'], 'Luis');
  });
}
