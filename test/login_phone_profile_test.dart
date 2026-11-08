import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/auth_gateway.dart';
import 'package:hackaton_hello_world/home/user_profile.dart';
import 'package:hackaton_hello_world/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthGateway implements AuthGateway {
  @override
  String? get currentUid => 'test-user';

  @override
  String? get currentDisplayName => null;

  @override
  Future<String> ensureSignedIn() async => 'test-user';

  @override
  Future<String> signInWithGoogle() async => 'test-user';

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPhoneCode(String phoneNumber) async {}

  @override
  Future<String> signInWithPhoneCode(String code) async => 'test-user';
}

class _PermissionDeniedProfileStore implements UserProfileStore {
  @override
  Future<bool> phoneExists(String phoneNumber) async => true;

  @override
  Future<UserProfile?> loadByPhone(
    String phoneNumber, {
    required String fallbackName,
    required String fallbackBio,
    required String fallbackDepartment,
    required String fallbackProvince,
    required String fallbackDistrict,
  }) async {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Missing or insufficient permissions.',
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
  }) async => null;

  @override
  Future<void> save(String uid, UserProfile profile) async {}
}

void main() {
  testWidgets(
    'continúa al barrio si no puede leer el perfil por permission-denied',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MyApp(
          authGateway: _FakeAuthGateway(),
          profileStore: _PermissionDeniedProfileStore(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar con celular'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '987654321');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Verificar y continuar'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verificar y continuar'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Completa tus datos para continuar'),
        findsOneWidget,
      );
      expect(find.text('Revisar distrito'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
