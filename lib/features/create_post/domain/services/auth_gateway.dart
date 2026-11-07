abstract interface class AuthGateway {
  String? get currentUid;

  Future<String> ensureSignedIn();
}

enum AuthFailureReason { noConnection, anonymousDisabled, unavailable }

final class AuthFailure implements Exception {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;
}
