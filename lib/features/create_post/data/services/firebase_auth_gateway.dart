import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/services/auth_gateway.dart';

final class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(this._auth);

  final FirebaseAuth _auth;
  Future<String>? _signInInFlight;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<String> ensureSignedIn() async {
    final uid = currentUid;
    if (uid != null) return uid;

    final pending = _signInInFlight ??= _signIn();
    try {
      return await pending;
    } finally {
      if (identical(_signInInFlight, pending)) _signInInFlight = null;
    }
  }

  Future<String> _signIn() async {
    try {
      final credential = await _auth.signInAnonymously();
      final uid = credential.user?.uid;
      if (uid == null) throw const AuthFailure(AuthFailureReason.unavailable);
      return uid;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(switch (error.code) {
        'network-request-failed' => AuthFailureReason.noConnection,
        'operation-not-allowed' ||
        'admin-restricted-operation' => AuthFailureReason.anonymousDisabled,
        _ => AuthFailureReason.unavailable,
      });
    }
  }
}
