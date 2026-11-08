import '../domain/models/app_user.dart';
import '../domain/services/period_provider.dart';

/// Pure migration plan. The repository reads all documents before writing it.
final class UserInitialization {
  UserInitialization({
    required Map<String, dynamic>? existing,
    required Map<String, dynamic>? account,
    required Map<String, dynamic>? proximity,
    required String uid,
    required String name,
    required String period,
  }) {
    final old = existing ?? <String, dynamic>{};
    publicData = Map<String, dynamic>.from(old)
      ..removeWhere((key, _) => privateKeys.contains(key) || key == 'level');
    publicData['name'] = (old['name'] as String?)?.trim().isNotEmpty == true
        ? old['name']
        : name.trim().isEmpty
        ? 'Vecino'
        : name.trim();
    publicData['xp'] = existing == null ? 20 : old['xp'] ?? 0;
    publicData['profileVersion'] = 1;
    publicData['districtKey'] = districtKey(old['district'] as String? ?? '');
    publicData['averageStars'] = old['averageStars'] ?? 0;
    publicData['reviewCount'] = AppUser.readInteger(old['reviewCount']);
    final storedPeriod = old['rankingPeriod'] as String? ?? '';
    publicData['rankingPeriod'] = needsMonthlyReset(storedPeriod, period)
        ? period
        : storedPeriod;
    publicData['monthlyXp'] = existing == null
        ? 20
        : needsMonthlyReset(storedPeriod, period)
        ? 0
        : old['monthlyXp'] ?? 0;
    privateData = {
      'phoneNumber': old['phoneNumber'] ?? old['telefono'] ?? '',
      'email': old['email'] ?? '',
      'availableCoins': existing == null
          ? 10
          : AppUser.readInteger(
              old['availableCoins'] ?? old['monedasDisponibles'],
            ),
      ...?account,
    };
    proximityData = {
      for (final key in proximityKeys)
        if (old.containsKey(key)) key: old[key],
      ...?proximity,
    };
    if (proximityData.isNotEmpty) {
      proximityData['kind'] = 'proximity';
      proximityData['uid'] = uid;
      proximityData.putIfAbsent('communityId', () => old['communityId'] ?? '');
      publicData.putIfAbsent('communityId', () => proximityData['communityId']);
    }
  }

  static const proximityKeys = {
    'proximityEnabled',
    'location',
    'geohash',
    'locationUpdatedAt',
    'fcmToken',
    'platform',
  };
  static const privateKeys = {
    ...proximityKeys,
    'phoneNumber',
    'telefono',
    'email',
    'availableCoins',
    'monedasDisponibles',
  };
  late final Map<String, dynamic> publicData;
  late final Map<String, dynamic> privateData;
  late final Map<String, dynamic> proximityData;
}
