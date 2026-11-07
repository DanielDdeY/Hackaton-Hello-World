const phoneTestCode = '123456';

abstract interface class AuthGateway {
  String? get currentUid;

  String? get currentDisplayName;

  Future<String> ensureSignedIn();

  Future<String> signInWithGoogle();

  Future<void> sendPhoneCode(String phoneNumber);

  Future<String> signInWithPhoneCode(String code);
}

enum AuthFailureReason {
  noConnection,
  anonymousDisabled,
  cancelled,
  invalidCode,
  tooManyRequests,
  unavailable,
}

final class AuthFailure implements Exception {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;
}
