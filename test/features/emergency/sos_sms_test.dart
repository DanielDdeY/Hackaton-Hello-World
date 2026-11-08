import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/emergency/data/sos_sms_composer.dart';
import 'package:hackaton_hello_world/features/emergency/data/sos_sms_contact_store.dart';
import 'package:hackaton_hello_world/features/emergency/domain/sos_sms_contact.dart';
import 'package:hackaton_hello_world/features/emergency/presentation/sos_sms_contacts_page.dart';

void main() {
  group('SosSmsContact', () {
    test('normalizes phone separators and validates international numbers', () {
      expect(
        SosSmsContact.normalizePhoneNumber(' +51 (987) 654-321 '),
        '+51987654321',
      );
      expect(SosSmsContact.normalizePhoneNumber('123'), isNull);
      expect(SosSmsContact.normalizePhoneNumber('+51 98x'), isNull);
      expect(SosSmsContact.normalizePhoneNumber('51+987654321'), isNull);
      expect(SosSmsContact.normalizePhoneNumber('++51987654321'), isNull);
    });
  });

  group('SosSmsComposer', () {
    test('builds a short message with timestamp and location link', () {
      final message = SosSmsComposer.buildMessage(
        now: DateTime(2026, 11, 8, 15, 5),
        latitude: -12.0464,
        longitude: -77.0428,
      );

      expect(message, contains('SOS VECINAL'));
      expect(message, contains('08/11/2026 15:05'));
      expect(message, contains('https://maps.google.com/?q=-12.0464,-77.0428'));
      expect(message, isNot(contains('null')));
    });

    test('does not claim location when coordinates are unavailable', () {
      final message = SosSmsComposer.buildMessage(
        now: DateTime(2026, 11, 8, 15, 5),
      );

      expect(message, contains('Ubicación no disponible'));
    });

    test(
      'prepares an SMS URI for one selected contact and a reviewed body',
      () {
        final uri = SosSmsComposer.buildUri(
          contacts: const [
            SosSmsContact(name: 'Ana', phoneNumber: '+51987654321'),
          ],
          message: 'SOS VECINAL: necesito ayuda',
        );

        expect(uri.scheme, 'sms');
        expect(uri.path, '+51987654321');
        expect(uri.queryParameters['body'], 'SOS VECINAL: necesito ayuda');
      },
    );

    test('opens the system composer only after an explicit request', () async {
      Uri? launchedUri;
      final composer = SosSmsComposer(
        supported: true,
        launch: (uri) async {
          launchedUri = uri;
          return true;
        },
      );
      final opened = await composer.openComposer(
        contacts: const [
          SosSmsContact(name: 'Ana', phoneNumber: '+51987654321'),
        ],
        message: 'SOS VECINAL',
      );

      expect(opened, isTrue);
      expect(launchedUri?.scheme, 'sms');
    });

    test('does not open a composer on unsupported targets', () async {
      var launchCalled = false;
      final composer = SosSmsComposer(
        supported: false,
        launch: (_) async {
          launchCalled = true;
          return true;
        },
      );

      expect(
        await composer.openComposer(
          contacts: const [
            SosSmsContact(name: 'Ana', phoneNumber: '987654321'),
          ],
          message: 'SOS VECINAL',
        ),
        isFalse,
      );
      expect(launchCalled, isFalse);
    });

    test('rejects empty or invalid recipient lists', () {
      expect(
        () => SosSmsComposer.buildUri(contacts: const [], message: 'SOS'),
        throwsArgumentError,
      );
      expect(
        () => SosSmsComposer.buildUri(
          contacts: const [SosSmsContact(name: 'Ana', phoneNumber: 'bad')],
          message: 'SOS',
        ),
        throwsArgumentError,
      );
      expect(
        () => SosSmsComposer.buildUri(
          contacts: const [
            SosSmsContact(name: 'Ana', phoneNumber: '+51987654321'),
            SosSmsContact(name: 'Luis', phoneNumber: '+51987123456'),
          ],
          message: 'SOS',
        ),
        throwsArgumentError,
      );
    });

    test('is only available on Android and iOS, not web', () {
      expect(
        SosSmsComposer.isSupportedPlatform(
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        isTrue,
      );
      expect(
        SosSmsComposer.isSupportedPlatform(
          isWeb: false,
          platform: TargetPlatform.iOS,
        ),
        isTrue,
      );
      expect(
        SosSmsComposer.isSupportedPlatform(
          isWeb: true,
          platform: TargetPlatform.android,
        ),
        isFalse,
      );
      expect(
        SosSmsComposer.isSupportedPlatform(
          isWeb: false,
          platform: TargetPlatform.windows,
        ),
        isFalse,
      );
    });
  });

  testWidgets('configures, validates, and removes trusted contacts', (
    tester,
  ) async {
    final store = _MemorySosSmsContactStore();
    await tester.pumpWidget(
      MaterialApp(home: SosSmsContactsPage(store: store)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aún no agregas contactos.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-sos-sms-contact')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('sos-sms-contact-name')),
      'Ana',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sos-sms-contact-phone')),
      '123',
    );
    await tester.tap(find.text('Guardar contacto'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ingresa un número válido (7 a 15 dígitos).'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('sos-sms-contact-phone')),
      '+51 987 654 321',
    );
    await tester.tap(find.text('Guardar contacto'));
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(store.contacts.single.phoneNumber, '+51987654321');

    await tester.tap(find.byTooltip('Eliminar contacto Ana'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsNothing);
    expect(store.contacts, isEmpty);
  });

  testWidgets('rejects invalid numbers and duplicate contacts', (tester) async {
    final store = _MemorySosSmsContactStore()
      ..contacts.add(
        const SosSmsContact(name: 'Ana', phoneNumber: '+51987654321'),
      );
    await tester.pumpWidget(
      MaterialApp(home: SosSmsContactsPage(store: store)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-sos-sms-contact')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('sos-sms-contact-name')),
      'Otra Ana',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sos-sms-contact-phone')),
      '+51 987 654 321',
    );
    await tester.tap(find.text('Guardar contacto'));
    await tester.pumpAndSettle();

    expect(find.text('Ese número ya está registrado.'), findsOneWidget);
    expect(store.contacts, hasLength(1));
  });
}

final class _MemorySosSmsContactStore implements SosSmsContactStore {
  final List<SosSmsContact> contacts = [];

  @override
  Future<List<SosSmsContact>> readContacts() async => List.of(contacts);

  @override
  Future<void> saveContacts(List<SosSmsContact> value) async {
    contacts
      ..clear()
      ..addAll(value);
  }
}
