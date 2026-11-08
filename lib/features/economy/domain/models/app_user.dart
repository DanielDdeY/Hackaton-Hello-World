import '../services/period_provider.dart';

/// Economic view of the existing users document, not a second profile.
final class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.district,
    required this.currentPeriod,
    this.xpTotal = 0,
    this.monthlyXp = 0,
    this.rankingPeriod = '',
    this.availableCoins = 0,
    this.averageStars = 0,
    this.reviewCount = 0,
  });

  factory AppUser.fromMap(
    String uid,
    Map<String, dynamic> data, {
    required String currentPeriod,
    Map<String, dynamic> privateAccount = const {},
  }) => AppUser(
    uid: uid,
    name: (data['name'] as String?)?.trim().isNotEmpty == true
        ? data['name'] as String
        : 'Vecino',
    district: data['district'] as String? ?? '',
    currentPeriod: currentPeriod,
    xpTotal: readInteger(data['xp']),
    monthlyXp: readInteger(data['monthlyXp']),
    rankingPeriod: data['rankingPeriod'] as String? ?? '',
    availableCoins: readInteger(privateAccount['availableCoins']),
    averageStars: (data['averageStars'] as num?)?.toDouble() ?? 0,
    reviewCount: readInteger(data['reviewCount']),
  );

  final String uid;
  final String name;
  final String district;
  final String currentPeriod;
  final int xpTotal;
  final int monthlyXp;
  final String rankingPeriod;
  final int availableCoins;
  final double averageStars;
  final int reviewCount;

  int get level => xpTotal ~/ 100;
  int get effectiveMonthlyXp => rankingPeriod == currentPeriod ? monthlyXp : 0;
  bool get needsReset => needsMonthlyReset(rankingPeriod, currentPeriod);

  /// Only editable profile data. Economic fields belong to transactions.
  Map<String, Object> toMap() => {'name': name, 'district': district};

  static int readInteger(Object? value) => value is num ? value.toInt() : 0;
}

String districtKey(String district) {
  var value = district.trim().toLowerCase();
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  for (final entry in accents.entries) {
    value = value.replaceAll(entry.key, entry.value);
  }
  return value.replaceAll(RegExp(r'\s+'), ' ');
}
