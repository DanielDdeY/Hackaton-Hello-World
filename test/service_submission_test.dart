import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hackaton_hello_world/features/create_post/data/mappers/firestore_post_mapper.dart';
import 'package:hackaton_hello_world/features/create_post/data/mocks/mock_photo_picker.dart';
import 'package:hackaton_hello_world/features/create_post/data/repositories/firestore_post_repository.dart';
import 'package:hackaton_hello_world/features/create_post/data/repositories/post_document_store.dart';
import 'package:hackaton_hello_world/features/create_post/data/services/profile_post_author_name_resolver.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/post_failure.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/post_form_data.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/service_availability.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/service_category.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/service_post_data.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/auth_gateway.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/image_uploader.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/photo_picker.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/post_cancellation.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/post_repository.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/service_category_classifier.dart';
import 'package:hackaton_hello_world/features/create_post/presentation/forms/services/service_availability_validator.dart';
import 'package:hackaton_hello_world/features/create_post/presentation/forms/services/service_form.dart';
import 'package:hackaton_hello_world/features/create_post/presentation/forms/services/service_form_controller.dart';
import 'package:hackaton_hello_world/features/create_post/presentation/submission/post_submission_controller.dart';
import 'package:hackaton_hello_world/home/user_profile.dart';

class _Classifier implements ServiceCategoryClassifier {
  (String, String)? input;

  @override
  ServiceCategory classify({
    required String title,
    required String information,
  }) {
    input = (title, information);
    return ServiceCategory.technology;
  }
}

class _Auth extends Fake implements AuthGateway {
  var calls = 0;

  @override
  Future<String> ensureSignedIn() async {
    calls++;
    return 'owner';
  }
}

class _Repository implements PostRepository {
  final drafts = <PostFormData>[];
  bool fail = false;
  Completer<void>? pending;

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
    await pending?.future;
    if (fail) throw const PostFailure(PostFailureReason.offline);
    onSaving?.call();
    return 'post';
  }
}

class _Documents implements PostDocumentStore {
  _Documents(this.events);
  final List<String> events;
  Map<String, Object?>? saved;
  bool fail = false;

  @override
  String newId() => 'post';

  @override
  Future<void> create(String id, Map<String, Object?> data) async {
    events.add('save');
    if (fail) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    saved = data;
  }

  @override
  Future<void> update(String id, Map<String, Object?> data) async {
    throw StateError('Servicios no debe guardar antes de terminar la subida.');
  }
}

const _photo = UploadedPhoto(
  storagePath: 'posts/owner/post/0_123.jpg',
  downloadUrl: 'https://example.invalid/photo.jpg',
);

class _Uploader implements ImageUploader {
  _Uploader(this.events);
  final List<String> events;
  final pending = Completer<List<UploadedPhoto>>();
  List<String>? deleted;

  @override
  Future<List<UploadedPhoto>> uploadAll({
    required String authorId,
    required String postId,
    required List<String> localPaths,
    void Function(double)? onProgress,
    PostCancellation? cancellation,
  }) async {
    events.add('upload');
    expect(localPaths, ['service.jpg']);
    onProgress?.call(0.5);
    return pending.future;
  }

  @override
  Future<void> deleteAll(List<String> storagePaths) async {
    events.add('rollback');
    deleted = storagePaths;
  }
}

class _Profiles extends Fake implements UserProfileStore {
  String? uid;
  String? name;
  @override
  Future<UserProfile?> load(
    String uid, {
    required String fallbackName,
    required String fallbackBio,
    required String fallbackDepartment,
    required String fallbackProvince,
    required String fallbackDistrict,
  }) async {
    this.uid = uid;
    expect(fallbackName, 'Vecino');
    if (name == null) return null;
    return UserProfile(
      name: name!,
      phoneNumber: '',
      role: 'Vecino',
      bio: '',
      department: '',
      province: '',
      district: '',
      xp: 0,
      stars: 0,
      favors: 0,
      tools: 0,
      petHunger: 0,
    );
  }
}

ServiceFormController _controller([_Classifier? classifier]) =>
    ServiceFormController(
      photoPicker: const MockPhotoPicker(),
      classifier: classifier ?? _Classifier(),
    );

void _fill(ServiceFormController controller) {
  controller.titleController.text = ' Reparación de laptops ';
  controller.descriptionController.text = ' Formateo y antivirus ';
  controller.amountController.text = '25,50';
  controller.phoneController.text = '987654321';
  controller.toggleDay(Weekday.monday);
  controller.setStartTime(const TimeOfDay(hour: 9, minute: 0));
  controller.setEndTime(const TimeOfDay(hour: 17, minute: 30));
  controller.setPaymentMethods({PaymentMethod.yape, PaymentMethod.bcpTransfer});
}

Finder _field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _open(WidgetTester tester, _Repository repository) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AuthGateway?>.value(value: _Auth()),
        Provider<PostRepository?>.value(value: repository),
        Provider<PhotoPicker>.value(value: const MockPhotoPicker()),
        Provider<ServiceCategoryClassifier>.value(value: _Classifier()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const ServiceForm()),
              ),
              child: const Text('Abrir Servicios'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir Servicios'));
  await tester.pumpAndSettle();
}

Future<void> _fillSale(WidgetTester tester) async {
  await tester.enterText(
    _field('Título (Obligatorio)'),
    'Reparación de laptops',
  );
  await tester.enterText(
    _field('Información (Obligatorio)'),
    'Formateo y antivirus',
  );
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Vender'));
  await tester.pumpAndSettle();
  await tester.enterText(_field('Monto a cobrar (Obligatorio)'), '25.50');
  await tester.enterText(_field('Número (Obligatorio)'), '987654321');
  await tester.enterText(_field('Cantidad / Stock (Obligatorio)'), '2');
  await tester.pumpAndSettle();
}

void main() {
  test('controlador clasifica y mapper conserva el esquema y solo la modalidad activa', () {
    final classifier = _Classifier();
    final controller = _controller(classifier);
    addTearDown(controller.dispose);
    _fill(controller);
    controller.stockController.text = '3';
    final data = controller.data;
    final mapped = FirestorePostMapper.create(
      data,
      postId: 'post',
      authorId: 'owner',
      authorName: 'Ana',
      mediaStatus: PostMediaStatus.none,
    );
    expect(classifier.input, ('Reparación de laptops', 'Formateo y antivirus'));
    expect(mapped, containsPair('category', 'service'));
    expect(mapped, containsPair('authorName', 'Ana'));
    expect(mapped['createdAt'], isA<FieldValue>());
    expect(mapped['details'], {
      'title': 'Reparación de laptops',
      'information': 'Formateo y antivirus',
      'serviceCategory': 'technology',
      'categorySource': 'keyword',
      'mode': 'provide_service',
      'price': 25.5,
      'currency': 'PEN',
      'paymentMethods': ['yape', 'bank_transfer'],
      'transferBanks': ['bcp'],
      'contactPhone': '987654321',
      'availability': {
        'days': ['mon'],
        'startTime': '09:00',
        'endTime': '17:30',
      },
    });
    controller.setMode(ServiceMode.sell);
    final sale = controller.data.toMap();
    expect(sale['mode'], 'sell');
    expect(sale['stock'], 3);
    expect(sale.containsKey('availability'), isFalse);
    controller.setMode(ServiceMode.provideService);
    expect(controller.data.toMap().containsKey('stock'), isFalse);
    expect(controller.data.isValid, isTrue);
  });

  final invalidCases = <String, void Function(ServiceFormController)>{
    'título vacío': (c) => c.titleController.text = ' ',
    'información vacía': (c) => c.descriptionController.text = '',
    'monto negativo': (c) => c.amountController.text = '-1',
    'monto con tres decimales': (c) => c.amountController.text = '1.123',
    'teléfono no empieza en 9': (c) => c.phoneController.text = '887654321',
    'teléfono corto': (c) => c.phoneController.text = '98765432',
    'sin días': (c) => c.toggleDay(Weekday.monday),
    'sin horas': (c) {
      c.clearAvailability();
      c.toggleDay(Weekday.monday);
    },
    'fin igual a inicio': (c) =>
        c.setEndTime(const TimeOfDay(hour: 9, minute: 0)),
    'fin anterior a inicio': (c) =>
        c.setEndTime(const TimeOfDay(hour: 8, minute: 59)),
    'stock cero': (c) {
      c.setMode(ServiceMode.sell);
      c.stockController.text = '0';
    },
    'stock decimal': (c) {
      c.setMode(ServiceMode.sell);
      c.stockController.text = '1.5';
    },
  };
  for (final entry in invalidCases.entries) {
    test('${entry.key}: no inicia sesión ni llama al repositorio', () async {
      final controller = _controller();
      final auth = _Auth();
      final repository = _Repository();
      final submission = PostSubmissionController(
        auth: auth,
        repository: repository,
      );
      addTearDown(controller.dispose);
      addTearDown(submission.dispose);
      _fill(controller);
      entry.value(controller);
      expect(await submission.submit(() => controller.data), isNull);
      expect(submission.failure, PostFailureReason.invalid);
      expect(repository.drafts, isEmpty);
      expect(auth.calls, 0);
    });
  }

  test('servicio gratuito válido sin disponibilidad', () {
    final controller = _controller();
    addTearDown(controller.dispose);
    _fill(controller);
    controller.amountController.text = '0';
    controller.clearAvailability();
    expect(controller.data.isValid, isTrue);
    expect(controller.data.toMap()['price'], 0);
    expect(controller.data.toMap().containsKey('availability'), isFalse);
    expect(ServiceAvailabilityValidator.validate(null), isNull);
  });

  test('envío válido una sola vez, clasificado; conserva borrador y permite reintento', () async {
    final controller = _controller();
    final repository = _Repository()..fail = true;
    final submission = PostSubmissionController(
      auth: _Auth(),
      repository: repository,
    );
    addTearDown(controller.dispose);
    addTearDown(submission.dispose);
    _fill(controller);
    expect(await submission.submit(() => controller.data), isNull);
    expect(submission.failure, PostFailureReason.offline);
    expect(repository.drafts, hasLength(1));
    expect(controller.amountController.text, '25,50');
    expect(controller.days, {Weekday.monday});
    expect(controller.paymentMethods, {
      PaymentMethod.yape,
      PaymentMethod.bcpTransfer,
    });
    repository.fail = false;
    repository.pending = Completer<void>();
    final retry = submission.submit(() => controller.data);
    await Future<void>.delayed(Duration.zero);
    expect(submission.isBusy, isTrue);
    expect(await submission.submit(() => controller.data), isNull);
    repository.pending!.complete();
    expect(await retry, 'post');
    expect(repository.drafts, hasLength(2));
    expect(
      (repository.drafts.last as ServicePostData).serviceCategory,
      ServiceCategory.technology,
    );
    expect(submission.state, PostSubmissionState.success);
  });

  for (final failure in [false, true]) {
    test(
      'sube antes de guardar${failure ? ' y elimina la foto si Firestore falla' : ' con progreso y nombre del perfil'}',
      () async {
        final events = <String>[];
        final documents = _Documents(events)..fail = failure;
        final uploader = _Uploader(events);
        final profiles = _Profiles()..name = ' Ana García ';
        final repo = FirestorePostRepository(
          documents: documents,
          uploader: uploader,
          authorNameResolver: ProfilePostAuthorNameResolver(profiles),
        );
        final controller = _controller();
        addTearDown(controller.dispose);
        _fill(controller);
        controller.setAttachmentPath('service.jpg');
        final progress = <double>[];
        final result = repo.publish(
          controller.data,
          authorId: 'owner',
          cancellation: PostCancellation(),
          onUploadProgress: progress.add,
        );
        final check = failure
            ? expectLater(
                result,
                throwsA(
                  isA<PostFailure>().having(
                    (e) => e.reason,
                    'reason',
                    PostFailureReason.permissionDenied,
                  ),
                ),
              )
            : expectLater(result, completion('post'));
        await Future<void>.delayed(Duration.zero);
        expect(events, ['upload']);
        expect(documents.saved, isNull);
        uploader.pending.complete([_photo]);
        await check;
        expect(profiles.uid, 'owner');
        expect(progress, [0, 0.5]);
        expect(
          events,
          failure ? ['upload', 'save', 'rollback'] : ['upload', 'save'],
        );
        if (failure) {
          expect(uploader.deleted, [_photo.storagePath]);
          expect(documents.saved, isNull);
        } else {
          expect(documents.saved!['authorName'], 'Ana García');
          expect(documents.saved!['mediaStatus'], 'ready');
          expect(documents.saved!['photos'], [
            {
              'storagePath': _photo.storagePath,
              'downloadUrl': _photo.downloadUrl,
            },
          ]);
        }
      },
    );
  }

  test('subida fallida no crea un documento', () async {
    final events = <String>[];
    final documents = _Documents(events);
    final uploader = _Uploader(events);
    final controller = _controller();
    addTearDown(controller.dispose);
    _fill(controller);
    controller.setAttachmentPath('service.jpg');
    final result =
        FirestorePostRepository(
          documents: documents,
          uploader: uploader,
        ).publish(
          controller.data,
          authorId: 'owner',
          cancellation: PostCancellation(),
        );
    final check = expectLater(
      result,
      throwsA(
        isA<PostFailure>().having(
          (e) => e.reason,
          'reason',
          PostFailureReason.upload,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    uploader.pending.completeError(
      const ImageUploadException(PostFailureReason.upload),
    );
    await check;
    expect(events, ['upload']);
    expect(documents.saved, isNull);
  });

  test(
    'sin foto guarda directamente; usa Vecino sin perfil o nombre',
    () async {
      final controller = _controller();
      addTearDown(controller.dispose);
      _fill(controller);
      for (final name in <String?>[null, '   ']) {
        final events = <String>[];
        final documents = _Documents(events);
        final profiles = _Profiles()..name = name;
        final repo = FirestorePostRepository(
          documents: documents,
          uploader: _Uploader(events),
          authorNameResolver: ProfilePostAuthorNameResolver(profiles),
        );
        await repo.publish(
          controller.data,
          authorId: 'owner',
          cancellation: PostCancellation(),
        );
        expect(events, ['save']);
        expect(documents.saved!['authorName'], 'Vecino');
        expect(documents.saved!['mediaStatus'], 'none');
        expect(documents.saved!['photos'], isEmpty);
      }
    },
  );

  testWidgets('formulario inválido no publica ni cierra', (tester) async {
    final repository = _Repository();
    await _open(tester, repository);
    await _tap(tester, find.text('Publicar'));
    await tester.pumpAndSettle();
    expect(repository.drafts, isEmpty);
    expect(find.byType(ServiceForm), findsOneWidget);
    expect(find.text('Disponibilidad (Opcional)'), findsOneWidget);
  });

  testWidgets('Brindar servicio guarda los días seleccionados', (tester) async {
    final repository = _Repository();
    await _open(tester, repository);
    await tester.enterText(
      _field('Título (Obligatorio)'),
      'Reparación de laptops',
    );
    await tester.enterText(
      _field('Información (Obligatorio)'),
      'Formateo y antivirus',
    );
    await tester.enterText(_field('Monto a cobrar (Obligatorio)'), '25');
    await tester.enterText(_field('Número (Obligatorio)'), '987654321');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Lun'));
    await _tap(tester, find.text('Hora de inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Hora de fin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Publicar'));
    await tester.pumpAndSettle();
    final data = repository.drafts.single as ServicePostData;
    expect(data.mode, ServiceMode.provideService);
    expect(data.toMap()['availability'], {
      'days': ['mon'],
      'startTime': '09:00',
      'endTime': '17:00',
    });
    expect(data.toMap().containsKey('stock'), isFalse);
    expect(find.text('Abrir Servicios'), findsOneWidget);
  });

  testWidgets(
    'falla, conserva campos y reintenta; confirma en la pantalla anterior',
    (tester) async {
      final repository = _Repository()..fail = true;
      await _open(tester, repository);
      await _fillSale(tester);
      await _tap(tester, find.text('Publicar'));
      await tester.pumpAndSettle();
      expect(repository.drafts, hasLength(1));
      expect(
        find.text('Sin conexión. Conéctate y vuelve a tocar Publicar.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(_field('Título (Obligatorio)'))
            .controller!
            .text,
        'Reparación de laptops',
      );
      expect(
        tester
            .widget<TextField>(_field('Cantidad / Stock (Obligatorio)'))
            .controller!
            .text,
        '2',
      );
      repository.fail = false;
      repository.pending = Completer<void>();
      // El mensaje de error temporal se superpone al pie del formulario.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Publicar'));
      expect(find.text('Publicando…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(repository.drafts, hasLength(2));
      expect(find.byType(ServiceForm), findsNothing);
      expect(find.text('Abrir Servicios'), findsOneWidget);
      expect(find.text('Publicación creada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
