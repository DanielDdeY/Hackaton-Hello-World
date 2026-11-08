import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/create_post/data/mappers/firestore_post_mapper.dart';
import 'package:hackaton_hello_world/features/create_post/data/mocks/mock_photo_picker.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/emergency_post_data.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/location_result.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/post_failure.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/post_form_data.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/post_location.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/auth_gateway.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/location_provider.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/photo_picker.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/post_cancellation.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/post_repository.dart';
import 'package:hackaton_hello_world/features/create_post/presentation/forms/emergency/emergency_form.dart';
import 'package:hackaton_hello_world/features/create_post/presentation/forms/help/help_form.dart';
import 'package:hackaton_hello_world/features/create_post/presentation/pages/category_selector_page.dart';
import 'package:provider/provider.dart';

class _Auth implements AuthGateway {
  var requests = 0;

  @override
  String get currentUid => 'owner';

  @override
  String? get currentDisplayName => 'Test User';

  @override
  Future<String> ensureSignedIn() async {
    requests++;
    return currentUid;
  }

  @override
  Future<String> signInWithGoogle() async => currentUid;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPhoneCode(String phoneNumber) async {}

  @override
  Future<String> signInWithPhoneCode(String code) async => currentUid;
}

class _Location implements DetailedLocationProvider {
  final capture = Completer<LocationResult>();
  final geocoding = Completer<String>();

  @override
  Future<LocationResult> getCurrentLocation() => capture.future;

  @override
  Future<String> getCurrentAddress() async =>
      resolveAddress(await getCurrentLocation());

  @override
  Future<String> resolveAddress(LocationResult location) => geocoding.future;
}

class _Repository implements PostRepository {
  final drafts = <PostFormData>[];
  bool failFirst = false;
  bool waitForCancel = false;
  bool cancelled = false;

  @override
  Future<String> publish(
    PostFormData data, {
    required String authorId,
    required PostCancellation cancellation,
    void Function(double progress)? onUploadProgress,
    void Function()? onSaving,
  }) async {
    expect(authorId, 'owner');
    drafts.add(data);
    if (failFirst && drafts.length == 1) {
      throw const PostFailure(PostFailureReason.offline);
    }
    if (waitForCancel) {
      onUploadProgress?.call(0.4);
      final done = Completer<void>();
      cancellation.addListener(done.complete);
      await done.future;
      cancelled = true;
      cancellation.check();
    }
    onSaving?.call();
    return 'post';
  }
}

Future<void> _open(
  WidgetTester tester,
  Widget form,
  _Auth auth,
  _Location location,
  _Repository repository,
) async {
  await tester.binding.setSurfaceSize(const Size(320, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AuthGateway?>.value(value: auth),
        Provider<LocationProvider>.value(value: location),
        Provider<PhotoPicker>.value(value: const MockPhotoPicker()),
        Provider<PostRepository?>.value(value: repository),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  Navigator.of(context)
                      .push<void>(MaterialPageRoute(builder: (_) => form)),
              child: const Text('Abrir formulario'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir formulario'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Finder _input(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pump();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pump();
}

void main() {
  testWidgets('Publicar abre Eventos y admite publicar sin campos opcionales', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = _Auth();
    final repository = _Repository();
    await _open(
      tester,
      const CategorySelectorPage(),
      auth,
      _Location(),
      repository,
    );
    expect(find.text('Servicios'), findsOneWidget);
    expect(find.text('Emergencia'), findsNothing);
    await _tap(tester, find.text('Eventos'));
    await tester.pumpAndSettle();
    expect(find.text('Publicar evento'), findsOneWidget);

    await _tap(tester, find.text('Publicar'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona un día y una hora.'), findsOneWidget);
    expect(repository.drafts, isEmpty);
    expect(auth.requests, 0);

    for (final (label, text) in [
      ('Título (obligatorio)', 'Reunión vecinal'),
      ('Lugar (obligatorio)', 'Local comunal'),
    ]) {
      final input = _input(label);
      await tester.ensureVisible(input);
      await tester.enterText(input, text);
      await tester.pumpAndSettle();
    }
    await _tap(tester, find.text('Elegir día'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').hitTestable());
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Elegir hora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Publicar'));
    await tester.pumpAndSettle();

    final saved = FirestorePostMapper.create(
      repository.drafts.single,
      postId: 'event',
      authorId: 'owner',
      mediaStatus: PostMediaStatus.none,
    );
    expect(saved['category'], 'event');
    expect(saved['details'], {
      'title': 'Reunión vecinal',
      'place': 'Local comunal',
      'startsAt': isA<Timestamp>(),
    });
    expect(find.text('Publicación creada.'), findsOneWidget);
  });

  testWidgets(
    'emergency with denied GPS submits the manually entered address',
    (tester) async {
      final auth = _Auth();
      final location = _Location();
      final repository = _Repository();
      await _open(tester, const EmergencyForm(), auth, location, repository);
      location.capture.completeError(
        const LocationUnavailableException(
          LocationUnavailableReason.permissionDenied,
        ),
      );
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Publicar'));
      expect(repository.drafts, isEmpty);
      expect(auth.requests, 0);
      await tester.ensureVisible(_input('CALLE (Obligatorio)'));
      await tester.enterText(_input('CALLE (Obligatorio)'), 'Jr. Lima 123');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Publicar'));
      await tester.pumpAndSettle();

      final saved = repository.drafts.single.locationData!;
      expect(saved.address, 'Jr. Lima 123');
      expect(saved.source, PostLocationSource.manual);
      expect(saved.coordinates, isNull);
      expect(find.text('Abrir formulario'), findsOneWidget);
      expect(find.text('Publicación creada.'), findsOneWidget);
    },
  );

  testWidgets('SOS report cannot publish until its title is entered', (
    tester,
  ) async {
    final auth = _Auth();
    final location = _Location();
    final repository = _Repository();
    await _open(
      tester,
      const EmergencyForm(sosAlertId: 'alert-id'),
      auth,
      location,
      repository,
    );
    location.capture.completeError(const LocationUnavailableException());
    await tester.pumpAndSettle();
    await tester.enterText(_input('CALLE (Obligatorio)'), 'Jr. Lima 123');

    await _tap(tester, find.text('Publicar'));
    expect(repository.drafts, isEmpty);
    expect(auth.requests, 0);

    await tester.enterText(_input('Título (Obligatorio)'), 'Accidente');
    await _tap(tester, find.text('Publicar'));
    await tester.pumpAndSettle();
    expect(repository.drafts, hasLength(1));
    expect((repository.drafts.single as EmergencyPostData).title, 'Accidente');
  });

  testWidgets('el formulario SOS ofrece DESASTRE y lo guarda como tipo', (
    tester,
  ) async {
    final auth = _Auth();
    final location = _Location();
    final repository = _Repository();
    await _open(
      tester,
      const EmergencyForm(sosAlertId: 'alert-id'),
      auth,
      location,
      repository,
    );
    location.capture.completeError(const LocationUnavailableException());
    await tester.pumpAndSettle();

    expect(find.text('DESASTRE'), findsOneWidget);
    expect(find.text('TRAGEDIA'), findsNothing);

    await tester.enterText(_input('CALLE (Obligatorio)'), 'Jr. Lima 123');
    await tester.enterText(_input('Título (Obligatorio)'), 'Desastre');
    await _tap(tester, find.text('DESASTRE'));
    await _tap(tester, find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(repository.drafts, hasLength(1));
    expect(
      (repository.drafts.single as EmergencyPostData).type,
      EmergencyType.disaster,
    );
  });

  testWidgets(
    'help captures GPS without opening Details and keeps a draft on retry',
    (tester) async {
      final auth = _Auth();
      final location = _Location();
      final repository = _Repository()..failFirst = true;
      await _open(tester, const HelpForm(), auth, location, repository);
      final description = _input('Descripción (Obligatorio)');
      expect(_input('Ubicación específica (Opcional)'), findsNothing);
      await tester.enterText(description, 'Necesito ayuda con una mudanza');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Publicar'));
      expect(find.text('Ingresa un número de celular.'), findsOneWidget);
      expect(repository.drafts, isEmpty);
      await tester.enterText(
        _input('Celular de WhatsApp (Obligatorio)'),
        '987654321',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Publicar'));
      expect(repository.drafts, isEmpty);
      expect(find.text('Publicando…'), findsOneWidget);

      const point = LocationResult(latitude: -12, longitude: -77);
      location.capture.complete(point);
      await tester.pumpAndSettle();
      expect(repository.drafts.single.locationData!.coordinates, point);
      expect(
        repository.drafts.single.locationData!.source,
        PostLocationSource.gps,
      );
      expect(
        find.text('Sin conexión. Conéctate y vuelve a tocar Publicar.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(description).controller!.text,
        'Necesito ayuda con una mudanza',
      );

      // The longer form scrolls the footer under the transient error snackbar.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Publicar'));
      await tester.pumpAndSettle();
      expect(repository.drafts, hasLength(2));
      expect(find.text('Publicación creada.'), findsOneWidget);
      location.geocoding.complete('Av. Lima');
      await tester.pump();
    },
  );

  testWidgets('help shows upload progress and confirms cancellation', (
    tester,
  ) async {
    final auth = _Auth();
    final location = _Location();
    final repository = _Repository()..waitForCancel = true;
    await _open(tester, const HelpForm(), auth, location, repository);
    location.capture.completeError(const LocationUnavailableException());
    await tester.pumpAndSettle();
    await tester.enterText(_input('Descripción (Obligatorio)'), 'Mudanza');
    await tester.enterText(
      _input('Celular de WhatsApp (Obligatorio)'),
      '987654321',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Agregar foto'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Elegir de la galería'));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    expect(find.text('Foto adjunta'), findsOneWidget);
    await _tap(tester, find.text('Publicar'));
    expect(find.text('40 %'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await _tap(tester, find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cancelar la subida?'), findsOneWidget);
    expect(repository.cancelled, isFalse);
    await _tap(tester, find.text('Cancelar subida'));
    await tester.pumpAndSettle();
    expect(repository.cancelled, isTrue);
    expect(find.text('Abrir formulario'), findsOneWidget);
  });
}
