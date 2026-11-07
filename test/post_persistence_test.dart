import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/core/validators/peruvian_phone_validator.dart';
import 'package:hackaton_hello_world/features/create_post/data/mappers/firestore_post_mapper.dart';
import 'package:hackaton_hello_world/features/create_post/data/mappers/geohash.dart';
import 'package:hackaton_hello_world/features/create_post/data/repositories/firestore_post_repository.dart';
import 'package:hackaton_hello_world/features/create_post/data/repositories/post_document_store.dart';
import 'package:hackaton_hello_world/features/create_post/data/services/firebase_photo_storage.dart';
import 'package:hackaton_hello_world/features/create_post/data/services/firebase_storage_image_uploader.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/emergency_post_data.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/help_post_data.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/location_result.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/news_post_data.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/post_failure.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/post_form_data.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/service_availability.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/service_post_data.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/image_uploader.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/post_cancellation.dart';

const _cachedPoint = LocationResult(
  latitude: -12.0464,
  longitude: -77.0428,
  isLastKnown: true,
);
const _photo = UploadedPhoto(
  storagePath: 'posts/owner/post/0_1000.jpg',
  downloadUrl: 'https://example.invalid/photo',
);

Map<String, Object?> _map(PostFormData data) => FirestorePostMapper.create(
  data,
  postId: 'post',
  authorId: 'owner',
  mediaStatus: PostMediaStatus.none,
);

class _Documents implements PostDocumentStore {
  _Documents(this.events);

  final List<String> events;
  final updated = Completer<Map<String, Object?>>();
  Map<String, Object?>? created;
  Object? createError;

  @override
  String newId() => 'post';

  @override
  Future<void> create(String id, Map<String, Object?> data) async {
    expect(id, 'post');
    events.add('create');
    if (createError case final error?) throw error;
    created = data;
  }

  @override
  Future<void> update(String id, Map<String, Object?> data) async {
    expect(id, 'post');
    events.add('update');
    updated.complete(data);
  }
}

class _Uploader implements ImageUploader {
  _Uploader(this.events);

  final List<String> events;
  final upload = Completer<List<UploadedPhoto>>();
  List<String> deleted = [];

  @override
  Future<List<UploadedPhoto>> uploadAll({
    required String authorId,
    required String postId,
    required List<String> localPaths,
    void Function(double progress)? onProgress,
    PostCancellation? cancellation,
  }) {
    expect((authorId, postId), ('owner', 'post'));
    expect(localPaths, ['test.jpg']);
    events.add('upload');
    return upload.future;
  }

  @override
  Future<void> deleteAll(List<String> paths) async {
    events.add('delete');
    deleted = paths;
  }
}

class _Task implements PhotoUpload {
  final updates = StreamController<double>.broadcast();
  final result = Completer<String>();
  bool cancelled = false;

  @override
  Stream<double> get progress => updates.stream;

  @override
  Future<String> finish() => result.future;

  @override
  Future<void> cancel() async {
    cancelled = true;
    if (!result.isCompleted) {
      result.completeError(
        const ImageUploadException(PostFailureReason.cancelled),
      );
    }
  }
}

class _Storage implements PhotoStorage {
  final tasks = <String, _Task>{};
  final storagePaths = <String, String>{};
  final deleted = <String>[];

  @override
  Future<PhotoUpload> start({
    required String storagePath,
    required String localPath,
    required String authorId,
    required String postId,
  }) async {
    expect((authorId, postId), ('owner', 'post'));
    storagePaths[localPath] = storagePath;
    final task = tasks[localPath] = _Task();
    addTearDown(task.updates.close);
    return task;
  }

  @override
  Future<void> delete(String storagePath) async => deleted.add(storagePath);
}

void main() {
  test('manual emergency without GPS omits geopoint, but edits keep GPS', () {
    final manual = _map(const EmergencyPostData(streetAddress: 'Jr. Lima 1'));
    expect(manual['location'], {'address': 'Jr. Lima 1', 'source': 'manual'});
    expect(manual['details'], {'type': 'robbery'});
    final edited = _map(
      const EmergencyPostData(
        streetAddress: 'Jr. Lima 2',
        coordinates: _cachedPoint,
        addressEditedByUser: true,
      ),
    );
    expect(edited['location'], {
      'address': 'Jr. Lima 2',
      'source': 'manual',
      'geopoint': const GeoPoint(-12.0464, -77.0428),
      'geohash': encodeGeohash(-12.0464, -77.0428),
      'isLastKnown': true,
      'addressEditedByUser': true,
    });
    expect(encodeGeohash(57.64911, 10.40744), 'u4pruydqq');
  });

  test('help dates use Firestore timestamps and news has no location', () {
    final help = _map(
      HelpPostData(
        description: 'Mudanza',
        neededBy: DateTime(2027, 2, 18),
        peopleCount: 2,
        hasReward: true,
        coordinates: _cachedPoint,
      ),
    );
    expect(help['details'], {
      'description': 'Mudanza',
      'requiredDate': Timestamp.fromDate(DateTime.utc(2027, 2, 18)),
      'peopleNeeded': 2,
      'hasReward': true,
    });
    expect(help['location'], containsPair('source', 'gps_last_known'));
    final cleared = _map(
      const HelpPostData(
        description: 'Mudanza',
        coordinates: _cachedPoint,
        addressEditedByUser: true,
      ),
    );
    expect(cleared['location'], containsPair('address', ''));
    expect(cleared['location'], containsPair('source', 'manual'));
    expect(
      cleared['location'],
      containsPair('geopoint', const GeoPoint(-12.0464, -77.0428)),
    );
    expect(help['createdAt'], isA<FieldValue>());
    expect(help['updatedAt'], isA<FieldValue>());
    expect(help.containsKey('photoUrls'), isFalse);
    expect(help['photos'], isEmpty);
    final news = _map(
      const NewsPostData(
        title: 'Corte de agua',
        description: 'Vuelve a las 18:00.',
        topic: NewsTopic.worksOrOutages,
      ),
    );
    expect(news.containsKey('location'), isFalse);
    expect(news['details'], {
      'title': 'Corte de agua',
      'content': 'Vuelve a las 18:00.',
      'quickCategory': 'service_cuts',
    });
  });

  test('service mode emits only its fields and keeps selected banks', () {
    final hours = ServiceAvailability(
      days: {Weekday.monday},
      startMinute: 480,
      endMinute: 765,
    );
    ServicePostData data(ServiceMode mode) => ServicePostData(
      title: 'Gasfitería',
      description: 'Reparaciones',
      amount: '25,50',
      phoneNumber: '987654321',
      mode: mode,
      stock: 2,
      availability: hours,
      paymentMethods: {
        PaymentMethod.yape,
        PaymentMethod.bcpTransfer,
        PaymentMethod.bbvaTransfer,
      },
    );
    final service = _map(data(ServiceMode.provideService));
    final details = service['details']! as Map<String, Object?>;
    expect(service['category'], 'service');
    expect(details['price'], 25.5);
    expect(details['paymentMethods'], ['yape', 'bank_transfer']);
    expect(details['transferBanks'], ['bcp', 'bbva']);
    expect(details['availability'], {
      'days': ['mon'],
      'startTime': '08:00',
      'endTime': '12:45',
    });
    expect(details.containsKey('stock'), isFalse);
    final sale =
        _map(data(ServiceMode.sell))['details']! as Map<String, Object?>;
    expect(sale['stock'], 2);
    expect(sale.containsKey('availability'), isFalse);
    expect(PeruvianPhoneValidator.isValid('987654321'), isTrue);
    for (final invalid in [
      '887654321',
      '98765432',
      '9876543210',
      '98765432a',
    ]) {
      expect(PeruvianPhoneValidator.isValid(invalid), isFalse);
    }
  });

  for (final fails in [false, true]) {
    test(
      'emergency returns before upload and later marks media ${fails ? 'failed' : 'ready'}',
      () async {
        final events = <String>[];
        final documents = _Documents(events);
        final uploader = _Uploader(events);
        final repo = FirestorePostRepository(
          documents: documents,
          uploader: uploader,
        );
        final id = await repo.publish(
          const EmergencyPostData(
            streetAddress: 'Av. Lima',
            photoPath: 'test.jpg',
          ),
          authorId: 'owner',
          cancellation: PostCancellation(),
        );
        expect(id, 'post');
        expect(events, ['create', 'upload']);
        expect(documents.created, containsPair('mediaStatus', 'uploading'));
        expect(documents.created!['photos'], isEmpty);
        if (fails) {
          uploader.upload.completeError(
            const ImageUploadException(PostFailureReason.upload),
          );
        } else {
          uploader.upload.complete([_photo]);
        }
        final update = await documents.updated.future;
        expect(update['mediaStatus'], fails ? 'failed' : 'ready');
        expect((update['photos']! as List).length, fails ? 0 : 1);
      },
    );
  }

  test(
    'help uploads first and rolls back when Firestore rejects the write',
    () async {
      final events = <String>[];
      final documents = _Documents(events)
        ..createError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
      final uploader = _Uploader(events)..upload.complete([_photo]);
      final repo = FirestorePostRepository(
        documents: documents,
        uploader: uploader,
      );
      await expectLater(
        repo.publish(
          const HelpPostData(description: 'Mudanza', photoPath: 'test.jpg'),
          authorId: 'owner',
          cancellation: PostCancellation(),
        ),
        throwsA(
          isA<PostFailure>().having(
            (error) => error.reason,
            'reason',
            PostFailureReason.offline,
          ),
        ),
      );
      expect(events, ['upload', 'create', 'delete']);
      expect(uploader.deleted, [_photo.storagePath]);
      expect(documents.created, isNull);
    },
  );

  test(
    'a failed parallel upload cancels other tasks and removes all paths',
    () async {
      final storage = _Storage();
      final progress = <double>[];
      final result = FirebaseStorageImageUploader(storage).uploadAll(
        authorId: 'owner',
        postId: 'post',
        localPaths: ['first.jpg', 'second.jpg', 'third.jpg'],
        onProgress: progress.add,
      );
      final assertion = expectLater(
        result,
        throwsA(
          isA<ImageUploadException>().having(
            (error) => error.reason,
            'reason',
            PostFailureReason.upload,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(storage.tasks, hasLength(3));
      storage.tasks['first.jpg']!.updates.add(0.5);
      storage.tasks['first.jpg']!.result.complete(_photo.downloadUrl);
      await Future<void>.delayed(Duration.zero);
      storage.tasks['second.jpg']!.result.completeError(
        const ImageUploadException(PostFailureReason.upload),
      );
      await assertion;
      expect(progress, contains(closeTo(1 / 6, 0.001)));
      expect(storage.tasks['third.jpg']!.cancelled, isTrue);
      expect(storage.deleted.toSet(), storage.storagePaths.values.toSet());
      expect(
        storage.storagePaths['first.jpg'],
        matches(r'^posts/owner/post/0_[0-9]+[.]jpg$'),
      );
    },
  );

  test(
    'cancelled upload removes the attempted file before completing',
    () async {
      final storage = _Storage();
      final cancellation = PostCancellation();
      final result = FirebaseStorageImageUploader(storage).uploadAll(
        authorId: 'owner',
        postId: 'post',
        localPaths: ['first.jpg'],
        cancellation: cancellation,
      );
      final assertion = expectLater(
        result,
        throwsA(
          isA<ImageUploadException>().having(
            (error) => error.reason,
            'reason',
            PostFailureReason.cancelled,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      cancellation.cancel();
      await assertion;
      expect(storage.tasks['first.jpg']!.cancelled, isTrue);
      expect(storage.deleted, [storage.storagePaths['first.jpg']]);
    },
  );
}
