import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/post_category.dart';
import '../../domain/entities/post_failure.dart';
import '../../domain/entities/post_form_data.dart';
import '../../domain/services/image_uploader.dart';
import '../../domain/services/post_cancellation.dart';
import '../../domain/services/post_repository.dart';
import '../../domain/services/post_author_name_resolver.dart';
import '../mappers/firestore_post_mapper.dart';
import 'post_document_store.dart';

final class FirestorePostRepository implements PostRepository {
  const FirestorePostRepository({
    required this._documents,
    required this._uploader,
    this._authorNameResolver,
  });

  final PostDocumentStore _documents;
  final ImageUploader _uploader;
  final PostAuthorNameResolver? _authorNameResolver;

  @override
  Future<String> publish(
    PostFormData data, {
    required String authorId,
    required PostCancellation cancellation,
    void Function(double progress)? onUploadProgress,
    void Function()? onSaving,
  }) async {
    if (authorId.isEmpty) throw const PostFailure(PostFailureReason.noSession);
    if (!data.isValid) throw const PostFailure(PostFailureReason.invalid);
    cancellation.check();
    final id = _documents.newId();
    final paths = List<String>.of(data.localPhotoPaths);
    var uploaded = const <UploadedPhoto>[];
    try {
      String? authorName;
      if (data.category == PostCategory.help ||
          data.category == PostCategory.services ||
          data.category == PostCategory.news) {
        final name = await _authorNameResolver?.resolve(authorId);
        authorName = name == null || name.trim().isEmpty
            ? 'Vecino'
            : name.trim();
        cancellation.check();
      }
      final uploadInBackground =
          data.category == PostCategory.emergency && paths.isNotEmpty;
      if (paths.isNotEmpty && !uploadInBackground) {
        onUploadProgress?.call(0);
        uploaded = await _uploader.uploadAll(
          authorId: authorId,
          postId: id,
          localPaths: paths,
          onProgress: onUploadProgress,
          cancellation: cancellation,
        );
      }
      cancellation.check();
      onSaving?.call();
      await _documents.create(
        id,
        FirestorePostMapper.create(
          data,
          postId: id,
          authorId: authorId,
          authorName: authorName,
          mediaStatus: uploadInBackground
              ? PostMediaStatus.uploading
              : uploaded.isEmpty
              ? PostMediaStatus.none
              : PostMediaStatus.ready,
          photos: uploaded,
        ),
      );
      if (uploadInBackground) {
        unawaited(_finishEmergency(id, authorId, paths));
      }
      return id;
    } catch (error) {
      try {
        await _deletePhotos(uploaded);
      } on ImageUploadException {
        throw const PostFailure(PostFailureReason.cleanup);
      }
      throw _failure(error);
    }
  }

  Future<void> _finishEmergency(
    String id,
    String authorId,
    List<String> paths,
  ) async {
    var uploaded = const <UploadedPhoto>[];
    try {
      uploaded = await _uploader.uploadAll(
        authorId: authorId,
        postId: id,
        localPaths: paths,
      );
      await _documents.update(
        id,
        FirestorePostMapper.mediaUpdate(PostMediaStatus.ready, uploaded),
      );
    } catch (_) {
      try {
        await _deletePhotos(uploaded);
      } on ImageUploadException {
        debugPrint('Emergency media cleanup failed.');
      }
      try {
        await _documents.update(
          id,
          FirestorePostMapper.mediaUpdate(PostMediaStatus.failed, const []),
        );
      } catch (_) {
        debugPrint('Emergency media status update failed.');
      }
    }
  }

  Future<void> _deletePhotos(List<UploadedPhoto> photos) async {
    if (photos.isEmpty) return;
    await _uploader.deleteAll([for (final photo in photos) photo.storagePath]);
  }

  static PostFailure _failure(Object error) => switch (error) {
    PostFailure() => error,
    ImageUploadException(:final reason) => PostFailure(reason),
    FirebaseException(:final code) => PostFailure(switch (code) {
      'unauthenticated' => PostFailureReason.noSession,
      'permission-denied' => PostFailureReason.permissionDenied,
      'unavailable' => PostFailureReason.offline,
      'deadline-exceeded' => PostFailureReason.timeout,
      _ => PostFailureReason.save,
    }),
    _ => const PostFailure(PostFailureReason.save),
  };
}
