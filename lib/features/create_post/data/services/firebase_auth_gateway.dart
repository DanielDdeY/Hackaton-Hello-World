import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/services/auth_gateway.dart';

final class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(this._auth);

  final FirebaseAuth _auth;
  Future<String>? _signInInFlight;
  Future<void>? _googleInitialization;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  String? get currentDisplayName => _auth.currentUser?.displayName;

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

  @override
  Future<String> signInWithGoogle() async {
    try {
      final credential = kIsWeb
          ? await _signInWithGoogleOnWeb()
          : await _signInWithGoogleOnNative();
      final user = _auth.currentUser;
      final result = user?.isAnonymous == true
          ? await user!.linkWithCredential(credential)
          : await _auth.signInWithCredential(credential);
      final uid = result.user?.uid;
      if (uid == null) throw const AuthFailure(AuthFailureReason.unavailable);
      return uid;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(switch (error.code) {
        'network-request-failed' => AuthFailureReason.noConnection,
        'popup-closed-by-user' ||
        'cancelled-popup-request' => AuthFailureReason.cancelled,
        _ => AuthFailureReason.unavailable,
      });
    } on GoogleSignInException catch (error) {
      throw AuthFailure(switch (error.code) {
        GoogleSignInExceptionCode.canceled => AuthFailureReason.cancelled,
        _ => AuthFailureReason.unavailable,
      });
    } on UnsupportedError {
      throw const AuthFailure(AuthFailureReason.unavailable);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPhoneCode(String phoneNumber) async {
    // The SMS step is intentionally simulated for the current prototype.
  }

  @override
  Future<String> signInWithPhoneCode(String code) async {
    if (code != phoneTestCode) {
      throw const AuthFailure(AuthFailureReason.invalidCode);
    }
    final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
    final uid = user?.uid;
    if (uid == null) throw const AuthFailure(AuthFailureReason.unavailable);
    return uid;
  }

  Future<AuthCredential> _signInWithGoogleOnWeb() async {
    final result = await _auth.signInWithPopup(GoogleAuthProvider());
    final credential = result.credential;
    if (credential == null) {
      throw const AuthFailure(AuthFailureReason.unavailable);
    }
    return credential;
  }

  Future<AuthCredential> _signInWithGoogleOnNative() async {
    _googleInitialization ??= GoogleSignIn.instance.initialize();
    await _googleInitialization;
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthFailure(AuthFailureReason.unavailable);
    }
    return GoogleAuthProvider.credential(idToken: idToken);
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
