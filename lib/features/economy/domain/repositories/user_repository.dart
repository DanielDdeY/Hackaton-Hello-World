import '../models/app_user.dart';

abstract interface class UserRepository {
  Future<AppUser> ensureUser({required String uid, String name = 'Vecino'});
  Stream<AppUser> watchUserStats(String uid);
  Stream<List<AppUser>> watchMonthlyLeaderboard({
    required String district,
    int limit = 50,
  });
  Stream<List<AppUser>> watchTopThreeOfMonth({required String district});
}

enum UserFailureReason {
  noSession,
  networkUnavailable,
  permissionDenied,
  notFound,
  unavailable,
}

final class UserFailure implements Exception {
  const UserFailure(this.reason);
  final UserFailureReason reason;
}
