import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/app_user.dart';
import '../domain/services/period_provider.dart';

/// Seeder de vecinos de demostración para poblar o limpiar el ranking mensual
/// del barrio durante pruebas y demostraciones (R12).
final class DemoRankingSeeder {
  const DemoRankingSeeder({
    required this.firestore,
    required this.periods,
  });

  final FirebaseFirestore firestore;
  final PeriodProvider periods;

  static const List<({String id, String name, int xp, int monthlyXp, double stars, int reviews})>
  _demoNeighbors = [
    (
    id: 'demo_vecino_1',
    name: 'Elena Quispe',
    xp: 640,
    monthlyXp: 185,
    stars: 4.9,
    reviews: 14,
    ),
    (
    id: 'demo_vecino_2',
    name: 'Marco Huamán',
    xp: 520,
    monthlyXp: 140,
    stars: 4.8,
    reviews: 11,
    ),
    (
    id: 'demo_vecino_3',
    name: 'Lucía Paredes',
    xp: 390,
    monthlyXp: 95,
    stars: 5.0,
    reviews: 8,
    ),
    (
    id: 'demo_vecino_4',
    name: 'Jorge Rojas',
    xp: 260,
    monthlyXp: 55,
    stars: 4.7,
    reviews: 6,
    ),
  ];

  String get _effectivePeriod {
    final provider = periods;
    if (provider is SimulatablePeriodProvider) {
      return provider.realPeriod;
    }
    return provider.currentPeriod;
  }

  /// Inserta o actualiza los 4 vecinos de demostración en el distrito indicado
  /// utilizando el periodo calculado dinámicamente en el momento.
  Future<int> seed({required String district}) async {
    final cleanDistrict = district.trim().isEmpty ? 'Ate' : district.trim();
    final key = districtKey(cleanDistrict);
    final period = _effectivePeriod;
    final batch = firestore.batch();

    for (final item in _demoNeighbors) {
      final ref = firestore.collection('users').doc(item.id);
      batch.set(ref, {
        'profileVersion': 1,
        'isDemo': true,
        'name': item.name,
        'firstName': item.name.split(' ').first,
        'lastName': item.name.split(' ').skip(1).join(' '),
        'bio': 'Vecino de demostración del barrio $cleanDistrict.',
        'district': cleanDistrict,
        'districtKey': key,
        'xp': item.xp,
        'monthlyXp': item.monthlyXp,
        'rankingPeriod': period,
        'averageStars': item.stars,
        'reviewCount': item.reviews,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    return _demoNeighbors.length;
  }

  /// Elimina por completo todos los documentos de demostración (`isDemo: true`).
  Future<int> clear() async {
    final batch = firestore.batch();
    var deleted = 0;

    for (final item in _demoNeighbors) {
      batch.delete(firestore.collection('users').doc(item.id));
      deleted++;
    }

    try {
      final extra = await firestore
          .collection('users')
          .where('isDemo', isEqualTo: true)
          .get();
      for (final doc in extra.docs) {
        if (!_demoNeighbors.any((d) => d.id == doc.id)) {
          batch.delete(doc.reference);
          deleted++;
        }
      }
    } catch (_) {
      // Si las reglas bloquean un query sin filtro de ranking, el borrado por IDs fijos igual se ejecuta.
    }

    await batch.commit();
    return deleted;
  }
}