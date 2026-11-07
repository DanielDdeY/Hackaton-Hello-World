import '../entities/post_failure.dart';
import 'post_cancellation.dart';

final class UploadedPhoto {
  const UploadedPhoto({required this.storagePath, required this.downloadUrl});

  final String storagePath;
  final String downloadUrl;
}

final class ImageUploadException implements Exception {
  const ImageUploadException(this.reason);

  final PostFailureReason reason;
}

abstract interface class ImageUploader {
  Future<List<UploadedPhoto>> uploadAll({
    required String authorId,
    required String postId,
    required List<String> localPaths,
    void Function(double progress)? onProgress,
    PostCancellation? cancellation,
  });

  Future<void> deleteAll(List<String> storagePaths);
}
