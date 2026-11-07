import '../entities/post_form_data.dart';
import 'post_cancellation.dart';

abstract interface class PostRepository {
  Future<String> publish(
    PostFormData data, {
    required String authorId,
    required PostCancellation cancellation,
    void Function(double progress)? onUploadProgress,
    void Function()? onSaving,
  });
}
