import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/emergency/data/sos_consent_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = SosConsentStore();

  test('guarda el consentimiento y permite reiniciarlo', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    expect(store.hasConsent(preferences), isFalse);

    await store.grant(preferences);
    expect(store.hasConsent(preferences), isTrue);

    await store.reset(preferences);
    expect(store.hasConsent(preferences), isFalse);
  });

  test('considera aceptada una versión superior guardada', () async {
    SharedPreferences.setMockInitialValues({
      'sos_consent_version': SosConsentStore.currentVersion + 1,
    });
    final preferences = await SharedPreferences.getInstance();

    expect(store.hasConsent(preferences), isTrue);
  });
}
