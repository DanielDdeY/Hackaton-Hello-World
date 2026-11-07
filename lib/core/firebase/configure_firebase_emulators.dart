import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

const firebaseEmulatorProjectId = 'demo-hackaton-hello-world';

Future<FirebaseApp> initializeVeciAppFirebase(FirebaseOptions options) async {
  const enabled = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  if (!kDebugMode || !enabled) {
    return Firebase.initializeApp(options: options);
  }

  final app = await Firebase.initializeApp(
    name: firebaseEmulatorProjectId,
    options: options.copyWith(
      apiKey: 'ADemoProjectApiKey000000000000000000000',
      projectId: firebaseEmulatorProjectId,
      storageBucket: '$firebaseEmulatorProjectId.firebasestorage.app',
    ),
  );

  const hostOverride = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  const host = hostOverride == '' ? '127.0.0.1' : hostOverride;
  const mapAndroidLoopback = hostOverride == '';

  await FirebaseAuth.instanceFor(app: app)
      .useAuthEmulator(host, 9099, automaticHostMapping: mapAndroidLoopback);
  FirebaseFirestore.instanceFor(
    app: app,
  ).useFirestoreEmulator(host, 8080, automaticHostMapping: mapAndroidLoopback);
  await FirebaseStorage.instanceFor(app: app)
      .useStorageEmulator(host, 9199, automaticHostMapping: mapAndroidLoopback);
  return app;
}
