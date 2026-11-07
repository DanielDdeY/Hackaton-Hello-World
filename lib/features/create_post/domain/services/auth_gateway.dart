abstract interface class AuthGateway {
  String? get currentUid;

  String? get currentDisplayName;

  Future<String> ensureSignedIn();

  Future<String> signInWithGoogle();
}

enum AuthFailureReason {
  noConnection,
  anonymousDisabled,
  cancelled,
  unavailable,
}

final class AuthFailure implements Exception {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;
}
