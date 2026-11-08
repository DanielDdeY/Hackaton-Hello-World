import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

final class UserProfile {
  const UserProfile({
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.bio,
    required this.department,
    required this.province,
    required this.district,
    required this.xp,
    required this.stars,
    required this.favors,
    required this.tools,
    required this.petHunger,
    this.weeklyXp = 0,
    this.badges = const <String>[],
    this.favoresCompletados = 0,
    this.eventosAsistidos = 0,
    this.reconocimientos = 0,
    this.rachaSemanal = 0,
    this.joinedAt,
  });

  factory UserProfile.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document, {
    required String fallbackName,
    required String fallbackBio,
    required String fallbackDepartment,
    required String fallbackProvince,
    required String fallbackDistrict,
  }) {
    final data = document.data() ?? const <String, dynamic>{};
    final stats = data['stats'] is Map
        ? Map<String, dynamic>.from(data['stats'] as Map)
        : const <String, dynamic>{};
    return UserProfile(
      name: _string(data['name'], fallbackName),
      phoneNumber: _string(data['phoneNumber'], ''),
      role: _string(data['role'], 'Vecino'),
      bio: _string(data['bio'], fallbackBio),
      department: _string(data['department'], fallbackDepartment),
      province: _string(data['province'], fallbackProvince),
      district: _string(data['district'], fallbackDistrict),
      xp: _integer(data['xp']),
      weeklyXp: _integer(data['weeklyXp'] ?? stats['xpPeriodo']),
      stars: _integer(data['stars']),
      favors: _integer(data['favors']),
      tools: _integer(data['tools']),
      petHunger: _double(data['petHunger'], 0),
      badges: _stringList(data['badges'] ?? data['insignias']),
      favoresCompletados: _integer(
        stats['favoresCompletados'] ??
            data['favoresCompletados'] ??
            data['favors'],
      ),
      eventosAsistidos: _integer(
        stats['eventosAsistidos'] ?? data['eventosAsistidos'],
      ),
      reconocimientos: _integer(
        stats['reconocimientos'] ?? data['reconocimientos'],
      ),
      rachaSemanal: _integer(stats['rachaSemanal'] ?? data['rachaSemanal']),
      joinedAt: _date(data['joinedAt']),
    );
  }

  final String name;
  final String phoneNumber;
  final String role;
  final String bio;
  final String department;
  final String province;
  final String district;
  final int xp;
  final int weeklyXp;
  final int stars;
  final int favors;
  final int tools;
  final double petHunger;
  final List<String> badges;
  final int favoresCompletados;
  final int eventosAsistidos;
  final int reconocimientos;
  final int rachaSemanal;
  final DateTime? joinedAt;

  int get level => xp ~/ 100;
  int get xpEnNivelActual => xp % 100;
  bool get petUnlocked => level >= 25;

  UserProfile copyWith({
    double? petHunger,
    int? weeklyXp,
    List<String>? badges,
    int? favoresCompletados,
    int? eventosAsistidos,
    int? reconocimientos,
    int? rachaSemanal,
  }) => UserProfile(
    name: name,
    phoneNumber: phoneNumber,
    role: role,
    bio: bio,
    department: department,
    province: province,
    district: district,
    xp: xp,
    weeklyXp: weeklyXp ?? this.weeklyXp,
    stars: stars,
    favors: favors,
    tools: tools,
    petHunger: petHunger ?? this.petHunger,
    badges: badges ?? this.badges,
    favoresCompletados: favoresCompletados ?? this.favoresCompletados,
    eventosAsistidos: eventosAsistidos ?? this.eventosAsistidos,
    reconocimientos: reconocimientos ?? this.reconocimientos,
    rachaSemanal: rachaSemanal ?? this.rachaSemanal,
    joinedAt: joinedAt,
  );

  Map<String, Object> toMap() => {
    'name': name,
    'firstName': name.trim().split(RegExp(r'\s+')).first,
    'lastName': name.trim().split(RegExp(r'\s+')).skip(1).join(' '),
    'phoneNumber': phoneNumber,
    'role': role,
    'bio': bio,
    'department': department,
    'province': province,
    'district': district,
    'xp': xp,
    'weeklyXp': weeklyXp,
    'level': level,
    'stars': stars,
    'favors': favors,
    'tools': tools,
    'petHunger': petHunger,
    'badges': badges,
    'stats': {
      'favoresCompletados': favoresCompletados,
      'eventosAsistidos': eventosAsistidos,
      'reconocimientos': reconocimientos,
      'rachaSemanal': rachaSemanal,
    },
    if (joinedAt != null) 'joinedAt': Timestamp.fromDate(joinedAt!),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static String _string(Object? value, String fallback) {
    return value is String && value.trim().isNotEmpty ? value : fallback;
  }

  static int _integer(Object? value) => value is num ? value.toInt() : 0;

  static double _double(Object? value, double fallback) {
    return value is num ? value.toDouble().clamp(0, 1).toDouble() : fallback;
  }

  static List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

abstract interface class UserProfileStore {
  Future<bool> phoneExists(String phoneNumber);

  Future<UserProfile?> loadByPhone(
    String phoneNumber, {
    required String fallbackName,
    required String fallbackBio,
    required String fallbackDepartment,
    required String fallbackProvince,
    required String fallbackDistrict,
  });

  Future<UserProfile?> load(
    String uid, {
    required String fallbackName,
    required String fallbackBio,
    required String fallbackDepartment,
    required String fallbackProvince,
    required String fallbackDistrict,
  });

  Future<void> save(String uid, UserProfile profile);
}

final class FirestoreUserProfileStore implements UserProfileStore {
  FirestoreUserProfileStore(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<bool> phoneExists(String phoneNumber) async {
    final document = await _firestore
        .collection('phoneIndex')
        .doc(phoneNumber)
        .get();
    return document.exists;
  }

  @override
  Future<UserProfile?> loadByPhone(
    String phoneNumber, {
    required String fallbackName,
    required String fallbackBio,
    required String fallbackDepartment,
    required String fallbackProvince,
    required String fallbackDistrict,
  }) async {
    final index = await _firestore
        .collection('phoneIndex')
        .doc(phoneNumber)
        .get();
    final uid = index.data()?['uid'];
    if (uid is! String || uid.isEmpty) return null;
    return load(
      uid,
      fallbackName: fallbackName,
      fallbackBio: fallbackBio,
      fallbackDepartment: fallbackDepartment,
      fallbackProvince: fallbackProvince,
      fallbackDistrict: fallbackDistrict,
    );
  }

  @override
  Future<UserProfile?> load(
    String uid, {
    required String fallbackName,
    required String fallbackBio,
    required String fallbackDepartment,
    required String fallbackProvince,
    required String fallbackDistrict,
  }) async {
    final document = await _firestore.collection('users').doc(uid).get();
    if (!document.exists) return null;
    return UserProfile.fromDocument(
      document,
      fallbackName: fallbackName,
      fallbackBio: fallbackBio,
      fallbackDepartment: fallbackDepartment,
      fallbackProvince: fallbackProvince,
      fallbackDistrict: fallbackDistrict,
    );
  }

  @override
  Future<void> save(String uid, UserProfile profile) async {
    await _firestore.collection('users').doc(uid).set(
      profile.toMap(),
      SetOptions(merge: true),
    );
    if (profile.phoneNumber.isEmpty) return;
    try {
      await _firestore.collection('phoneIndex').doc(profile.phoneNumber).set({
        'uid': uid,
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('No se pudo actualizar el índice del teléfono: $error');
    }
  }
}
