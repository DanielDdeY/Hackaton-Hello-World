import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/create_post/data/services/firebase_auth_gateway.dart';
import '../features/create_post/domain/services/auth_gateway.dart';
import '../features/economy/data/firestore_user_repository.dart';
import '../features/economy/domain/models/app_user.dart';
import '../features/economy/domain/repositories/user_repository.dart';
import '../features/economy/domain/services/period_provider.dart';

import '../features/economia/domain/entities/nivel_xp.dart';

final class UserProfile {
  const UserProfile({
    required this.name,
    required this.phoneNumber,
    required this.bio,
    required this.department,
    required this.province,
    required this.district,
    required this.xp,
    required this.stars,
    required this.favors,
    required this.tools,
    this.petHunger = 0,
    this.fichas = 0,
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
    Map<String, dynamic> privateAccount = const {},
  }) {
    final data = document.data() ?? const <String, dynamic>{};
    final stats = data['stats'] is Map
        ? Map<String, dynamic>.from(data['stats'] as Map)
        : const <String, dynamic>{};
    return UserProfile(
      name: _string(data['name'], fallbackName),
      phoneNumber: _string(
        privateAccount['phoneNumber'] ?? data['phoneNumber'],
        '',
      ),
      bio: _string(data['bio'], fallbackBio),
      department: _string(data['department'], fallbackDepartment),
      province: _string(data['province'], fallbackProvince),
      district: _string(data['district'], fallbackDistrict),
      xp: _integer(data['xp']),
      fichas: _integer(data['fichas'] ?? data['monedas'] ?? data['stars']),
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
  final String bio;
  final String department;
  final String province;
  final String district;
  final int xp;
  final int fichas;
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

  int get level => NivelXp.calcularNivel(xp);
  int get xpEnNivelActual => NivelXp.xpEnNivelActual(xp);
  bool get petUnlocked => NivelXp.mascotaDesbloqueada(xp);

  UserProfile copyWith({
    int? xp,
    int? fichas,
    int? stars,
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
    bio: bio,
    department: department,
    province: province,
    district: district,
    xp: xp ?? this.xp,
    fichas: fichas ?? this.fichas,
    weeklyXp: weeklyXp ?? this.weeklyXp,
    stars: stars ?? this.stars,
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
    'bio': bio,
    'department': department,
    'province': province,
    'district': district,
    'xp': xp,
    'fichas': fichas,
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
  FirestoreUserProfileStore(
    this._firestore, {
    AuthGateway? auth,
    UserRepository? users,
  }) : _auth =
           auth ??
           FirebaseAuthGateway(FirebaseAuth.instanceFor(app: _firestore.app)) {
    _users =
        users ??
        FirestoreUserRepository(
          firestore: _firestore,
          auth: _auth,
          periods: SystemPeriodProvider(),
        );
  }

  final FirebaseFirestore _firestore;
  final AuthGateway _auth;
  late final UserRepository _users;

  Future<String?> _ownPhone() async {
    final uid = _auth.currentUid;
    if (uid == null) return null;
    final ref = _firestore.collection('users').doc(uid);
    final account = await ref.collection('private').doc('account').get();
    if (account.exists) return account.data()?['phoneNumber'] as String?;
    final legacy = await ref.get();
    return legacy.data()?['phoneNumber'] as String?;
  }

  @override
  Future<bool> phoneExists(String phoneNumber) async =>
      phoneNumber.isNotEmpty && await _ownPhone() == phoneNumber;

  @override
  Future<UserProfile?> loadByPhone(
    String phoneNumber, {
    required String fallbackName,
    required String fallbackBio,
    required String fallbackDepartment,
    required String fallbackProvince,
    required String fallbackDistrict,
  }) async {
    final uid = _auth.currentUid;
    if (uid == null || !await phoneExists(phoneNumber)) return null;
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
    final ref = _firestore.collection('users').doc(uid);
    final document = await ref.get();
    if (!document.exists) return null;
    final account = uid == _auth.currentUid
        ? (await ref.collection('private').doc('account').get()).data() ??
              <String, dynamic>{}
        : <String, dynamic>{};
    return UserProfile.fromDocument(
      document,
      fallbackName: fallbackName,
      fallbackBio: fallbackBio,
      fallbackDepartment: fallbackDepartment,
      fallbackProvince: fallbackProvince,
      fallbackDistrict: fallbackDistrict,
      privateAccount: account,
    );
  }

  @override
  Future<void> save(String uid, UserProfile profile) async {
    await _users.ensureUser(uid: uid, name: profile.name);
    final ref = _firestore.collection('users').doc(uid);
    final batch = _firestore.batch();
    // Profile edits and feeding the pet must never replay old economic values.
    batch.update(ref, {
      'name': profile.name,
      'firstName': profile.name.trim().split(RegExp(r'\s+')).first,
      'lastName': profile.name.trim().split(RegExp(r'\s+')).skip(1).join(' '),
      'bio': profile.bio,
      'department': profile.department,
      'province': profile.province,
      'district': profile.district,
      'districtKey': districtKey(profile.district),
      'petHunger': profile.petHunger,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(ref.collection('private').doc('account'), {
      'phoneNumber': profile.phoneNumber,
    });
    await batch.commit();
  }
}
