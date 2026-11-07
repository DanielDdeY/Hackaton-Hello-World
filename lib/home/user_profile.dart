import 'package:cloud_firestore/cloud_firestore.dart';

final class UserProfile {
  const UserProfile({
    required this.name,
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
    return UserProfile(
      name: _string(data['name'], fallbackName),
      role: _string(data['role'], 'Vecino'),
      bio: _string(data['bio'], fallbackBio),
      department: _string(data['department'], fallbackDepartment),
      province: _string(data['province'], fallbackProvince),
      district: _string(data['district'], fallbackDistrict),
      xp: _integer(data['xp']),
      stars: _integer(data['stars']),
      favors: _integer(data['favors']),
      tools: _integer(data['tools']),
      petHunger: _double(data['petHunger'], 0),
    );
  }

  final String name;
  final String role;
  final String bio;
  final String department;
  final String province;
  final String district;
  final int xp;
  final int stars;
  final int favors;
  final int tools;
  final double petHunger;

  int get level => xp ~/ 100;
  bool get petUnlocked => level >= 25;

  UserProfile copyWith({double? petHunger}) => UserProfile(
        name: name,
        role: role,
        bio: bio,
        department: department,
        province: province,
        district: district,
        xp: xp,
        stars: stars,
        favors: favors,
        tools: tools,
        petHunger: petHunger ?? this.petHunger,
      );

  Map<String, Object> toMap() => {
        'name': name,
        'role': role,
        'bio': bio,
        'department': department,
        'province': province,
        'district': district,
        'xp': xp,
        'stars': stars,
        'favors': favors,
        'tools': tools,
        'petHunger': petHunger,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static String _string(Object? value, String fallback) {
    return value is String && value.trim().isNotEmpty ? value : fallback;
  }

  static int _integer(Object? value) => value is num ? value.toInt() : 0;

  static double _double(Object? value, double fallback) {
    return value is num ? value.toDouble().clamp(0, 1).toDouble() : fallback;
  }
}

abstract interface class UserProfileStore {
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
  Future<void> save(String uid, UserProfile profile) {
    return _firestore
        .collection('users')
        .doc(uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }
}
