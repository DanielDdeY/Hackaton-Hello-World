import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../create_post/domain/services/auth_gateway.dart';
import '../domain/models/app_user.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/services/period_provider.dart';
import 'user_initialization.dart';

final class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({
    required this.firestore,
    required this.auth,
    required this.periods,
  });

  final FirebaseFirestore firestore;
  final AuthGateway auth;
  final PeriodProvider periods;

  @override
  Future<AppUser> ensureUser({
    required String uid,
    String name = 'Vecino',
  }) async {
    if (uid.isEmpty || auth.currentUid != uid) {
      throw const UserFailure(UserFailureReason.noSession);
    }
    final userRef = firestore.collection('users').doc(uid);
    final provider = periods;
    final realPeriod = provider is SimulatablePeriodProvider
        ? provider.realPeriod
        : provider.currentPeriod;
    final accountRef = userRef.collection('private').doc('account');
    final proximityRef = userRef.collection('private').doc('proximity');
    try {
      return await firestore.runTransaction((transaction) async {
        final user = await transaction.get(userRef);
        final account = await transaction.get(accountRef);
        final proximity = await transaction.get(proximityRef);
        final plan = UserInitialization(
          existing: user.data(),
          account: account.data(),
          proximity: proximity.data(),
          uid: uid,
          name: name,
          period: realPeriod,
        );
        if (!user.exists) {
          plan.publicData['createdAt'] = FieldValue.serverTimestamp();
        }
        plan.publicData['updatedAt'] = FieldValue.serverTimestamp();
        transaction.set(userRef, plan.publicData);
        transaction.set(accountRef, plan.privateData);
        if (plan.proximityData.isNotEmpty) {
          transaction.set(proximityRef, plan.proximityData);
        }
        return AppUser.fromMap(
          uid,
          plan.publicData,
          currentPeriod: periods.currentPeriod,
          privateAccount: plan.privateData,
        );
      });
    } on FirebaseException catch (error) {
      throw UserFailure(switch (error.code) {
        'unavailable' ||
        'deadline-exceeded' => UserFailureReason.networkUnavailable,
        'permission-denied' => UserFailureReason.permissionDenied,
        _ => UserFailureReason.unavailable,
      });
    }
  }

  @override
  Stream<AppUser> watchUserStats(String uid) {
    late StreamController<AppUser> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    publicSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    privateSubscription;
    Timer? timer;
    Map<String, dynamic>? publicData;
    Map<String, dynamic>? privateData;
    void emit() {
      if (publicData != null && privateData != null && !controller.isClosed) {
        controller.add(
          AppUser.fromMap(
            uid,
            publicData!,
            currentPeriod: periods.currentPeriod,
            privateAccount: privateData!,
          ),
        );
      }
    }

    controller = StreamController<AppUser>(
      onListen: () {
        if (auth.currentUid != uid) {
          controller.addError(const UserFailure(UserFailureReason.noSession));
          return;
        }
        final user = firestore.collection('users').doc(uid);
        publicSubscription = user.snapshots().listen((snapshot) {
          publicData = snapshot.data();
          if (publicData == null) {
            controller.addError(const UserFailure(UserFailureReason.notFound));
          } else {
            emit();
          }
        }, onError: controller.addError);
        privateSubscription = user
            .collection('private')
            .doc('account')
            .snapshots()
            .listen((snapshot) {
              privateData = snapshot.data() ?? {};
              emit();
            }, onError: controller.addError);
        timer = Timer.periodic(const Duration(minutes: 1), (_) => emit());
      },
      onCancel: () async {
        timer?.cancel();
        await publicSubscription?.cancel();
        await privateSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<AppUser>> watchMonthlyLeaderboard({
    required String district,
    int limit = 50,
  }) {
    if (limit < 1 || limit > 100) throw ArgumentError.value(limit, 'limit');
    late StreamController<List<AppUser>> controller;
    StreamSubscription<List<AppUser>>? subscription;
    Timer? timer;
    String? activePeriod;
    void bind() {
      final period = periods.currentPeriod;
      if (period == activePeriod) return;
      activePeriod = period;
      unawaited(subscription?.cancel());
      subscription = _watchLeaderboardPeriod(district, period, limit).listen(
        (users) {
          if (activePeriod == period && !controller.isClosed) {
            controller.add(users);
          }
        },
        onError: (Object error, StackTrace stack) {
          if (activePeriod == period && !controller.isClosed) {
            controller.addError(error, stack);
          }
        },
      );
    }

    controller = StreamController<List<AppUser>>(
      onListen: () {
        bind();
        timer = Timer.periodic(const Duration(minutes: 1), (_) => bind());
      },
      onCancel: () async {
        timer?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<List<AppUser>> _watchLeaderboardPeriod(
    String district,
    String period,
    int limit,
  ) async* {
    await auth.ensureSignedIn();
    final query = firestore
        .collection('users')
        .where('profileVersion', isEqualTo: 1)
        .where('districtKey', isEqualTo: districtKey(district))
        .where('rankingPeriod', isEqualTo: period);
    AppUser read(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
        AppUser.fromMap(doc.id, doc.data(), currentPeriod: period);
    try {
      await for (final snapshot
          in query
              .where('monthlyXp', isGreaterThan: 0)
              .orderBy('monthlyXp', descending: true)
              .orderBy('xp', descending: true)
              .limit(limit)
              .snapshots()) {
        yield snapshot.docs.map(read).toList(growable: false);
      }
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') rethrow;
      yield* query.snapshots().map((snapshot) {
        final users =
            snapshot.docs
                .map(read)
                .where((user) => user.effectiveMonthlyXp > 0)
                .toList()
              ..sort((a, b) {
                final monthly = b.monthlyXp.compareTo(a.monthlyXp);
                if (monthly != 0) return monthly;
                final total = b.xpTotal.compareTo(a.xpTotal);
                return total != 0 ? total : b.uid.compareTo(a.uid);
              });
        return users.take(limit).toList(growable: false);
      });
    }
  }

  @override
  Stream<List<AppUser>> watchTopThreeOfMonth({required String district}) =>
      watchMonthlyLeaderboard(district: district, limit: 3);
}
