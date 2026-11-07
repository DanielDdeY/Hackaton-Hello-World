import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';

import '../../domain/entities/post_failure.dart';
import '../../domain/services/image_uploader.dart';
import '../../domain/services/post_cancellation.dart';
import 'firebase_photo_storage.dart';

final class FirebaseStorageImageUploader implements ImageUploader {
  const FirebaseStorageImageUploader(
    this._storage, {
    this.timeout = const Duration(seconds: 30),
  });

  final PhotoStorage _storage;
  final Duration timeout;

  @override
  Future<List<UploadedPhoto>> uploadAll({
    required String authorId,
    required String postId,
    required List<String> localPaths,
    void Function(double progress)? onProgress,
    PostCancellation? cancellation,
  }) {
    return _UploadBatch(
      storage: _storage,
      uploader: this,
      authorId: authorId,
      postId: postId,
      paths: List.of(localPaths),
      onProgress: onProgress,
    ).run(cancellation);
  }

  @override
  Future<void> deleteAll(List<String> storagePaths) async {
    try {
      await Future.wait(storagePaths.toSet().map(_storage.delete));
    } on Exception {
      throw const ImageUploadException(PostFailureReason.cleanup);
    }
  }
}

final class _UploadBatch {
  _UploadBatch({
    required this.storage,
    required this.uploader,
    required this.authorId,
    required this.postId,
    required this.paths,
    required this.onProgress,
  }) : _fractions = List.filled(paths.length, 0);

  final PhotoStorage storage;
  final FirebaseStorageImageUploader uploader;
  final String authorId;
  final String postId;
  final List<String> paths;
  final void Function(double progress)? onProgress;
  final List<double> _fractions;
  final _tasks = <String, PhotoUpload>{};
  PostFailureReason? _failure;
  Future<void>? _aborting;

  Future<List<UploadedPhoto>> run(PostCancellation? cancellation) async {
    if (paths.isEmpty) return const [];
    void cancel() => _fail(PostFailureReason.cancelled);
    cancellation?.addListener(cancel);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final results = await Future.wait([
        for (var index = 0; index < paths.length; index++)
          _upload(index, 'posts/$authorId/$postId/${index}_$timestamp.jpg'),
      ]);
      if (_failure case final failure?) {
        await _aborting;
        await uploader.deleteAll(_tasks.keys.toList());
        throw ImageUploadException(failure);
      }
      return results.whereType<UploadedPhoto>().toList(growable: false);
    } finally {
      cancellation?.removeListener(cancel);
    }
  }

  Future<UploadedPhoto?> _upload(int index, String storagePath) async {
    if (_failure != null) return null;
    try {
      final task = await storage.start(
        storagePath: storagePath,
        localPath: paths[index],
        authorId: authorId,
        postId: postId,
      );
      _tasks[storagePath] = task;
      final finished = task.finish();
      if (_failure != null) {
        final settled = finished.then<void>((_) {}, onError: (Object _) {});
        await _cancelTask(task);
        await settled.timeout(uploader.timeout, onTimeout: () {});
        return null;
      }

      final subscription = task.progress.listen(
        (fraction) => _report(index, fraction),
        onError: (Object _) {},
      );
      try {
        final url = await finished.timeout(uploader.timeout);
        _report(index, 1);
        return UploadedPhoto(storagePath: storagePath, downloadUrl: url);
      } finally {
        await subscription.cancel();
      }
    } catch (error) {
      _fail(_reason(error));
      return null;
    }
  }

  void _report(int index, double fraction) {
    if (_failure != null || !fraction.isFinite) return;
    _fractions[index] = math.max(
      _fractions[index],
      fraction.clamp(0.0, 1.0).toDouble(),
    );
    onProgress?.call(_fractions.reduce((a, b) => a + b) / _fractions.length);
  }

  void _fail(PostFailureReason reason) {
    if (_failure != null) return;
    _failure = reason;
    _aborting = Future.wait(_tasks.values.toList().map(_cancelTask));
  }

  static Future<void> _cancelTask(PhotoUpload task) async {
    try {
      await task.cancel();
    } on Exception {
      // Completed tasks can still be removed by their storage path.
    }
  }

  static PostFailureReason _reason(Object error) => switch (error) {
    ImageUploadException(:final reason) => reason,
    TimeoutException() => PostFailureReason.timeout,
    FirebaseException(:final code) => switch (code) {
      'unauthenticated' => PostFailureReason.noSession,
      'unauthorized' ||
      'permission-denied' => PostFailureReason.permissionDenied,
      'network-request-failed' || 'unavailable' => PostFailureReason.offline,
      'retry-limit-exceeded' ||
      'deadline-exceeded' => PostFailureReason.timeout,
      'canceled' || 'cancelled' => PostFailureReason.cancelled,
      _ => PostFailureReason.upload,
    },
    _ => PostFailureReason.upload,
  };
}
