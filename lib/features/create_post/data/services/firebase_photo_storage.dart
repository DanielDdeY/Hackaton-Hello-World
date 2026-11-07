import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/post_failure.dart';
import '../../domain/services/image_uploader.dart';

abstract interface class PhotoStorage {
  Future<PhotoUpload> start({
    required String storagePath,
    required String localPath,
    required String authorId,
    required String postId,
  });

  Future<void> delete(String storagePath);
}

abstract interface class PhotoUpload {
  Stream<double> get progress;
  Future<String> finish();
  Future<void> cancel();
}

final class FirebasePhotoStorage implements PhotoStorage {
  const FirebasePhotoStorage(this._storage);

  static const maxPhotoBytes = 5 * 1024 * 1024;

  final FirebaseStorage _storage;

  @override
  Future<PhotoUpload> start({
    required String storagePath,
    required String localPath,
    required String authorId,
    required String postId,
  }) async {
    final photo = XFile(localPath);
    final length = await photo.length();
    if (length >= maxPhotoBytes) {
      throw const ImageUploadException(PostFailureReason.tooLarge);
    }
    if (length < 3) {
      throw const ImageUploadException(PostFailureReason.invalidPhoto);
    }
    final header = await photo.openRead(0, 3).expand((bytes) => bytes).toList();
    if (header.length != 3 ||
        header[0] != 0xff ||
        header[1] != 0xd8 ||
        header[2] != 0xff) {
      throw const ImageUploadException(PostFailureReason.invalidPhoto);
    }

    final ref = _storage.ref(storagePath);
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'authorId': authorId, 'postId': postId},
    );
    final task = kIsWeb
        ? ref.putData(await photo.readAsBytes(), metadata)
        : ref.putFile(File(localPath), metadata);
    return _FirebasePhotoUpload(task, ref);
  }

  @override
  Future<void> delete(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}

final class _FirebasePhotoUpload implements PhotoUpload {
  const _FirebasePhotoUpload(this._task, this._reference);

  final UploadTask _task;
  final Reference _reference;

  @override
  Stream<double> get progress => _task.snapshotEvents.map(
    (snapshot) => snapshot.totalBytes <= 0
        ? 0.0
        : snapshot.bytesTransferred / snapshot.totalBytes,
  );

  @override
  Future<String> finish() async {
    await _task;
    return _reference.getDownloadURL();
  }

  @override
  Future<void> cancel() async {
    await _task.cancel();
  }
}
