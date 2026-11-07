import 'package:flutter/foundation.dart';

import '../../domain/entities/post_failure.dart';
import '../../domain/entities/post_form_data.dart';
import '../../domain/services/auth_gateway.dart';
import '../../domain/services/post_cancellation.dart';
import '../../domain/services/post_repository.dart';

enum PostSubmissionState { idle, uploading, saving, success, error }

final class PostSubmissionController extends ChangeNotifier {
  PostSubmissionController({required this._auth, required this._repository});

  final AuthGateway? _auth;
  final PostRepository? _repository;
  PostSubmissionState _state = PostSubmissionState.idle;
  PostFailureReason? _failure;
  double? _progress;
  PostCancellation? _cancellation;
  Future<String?>? _inFlight;
  bool _disposed = false;

  PostSubmissionState get state => _state;
  PostFailureReason? get failure => _failure;
  double? get progress => _progress;
  bool get isBusy =>
      _state == PostSubmissionState.saving ||
      _state == PostSubmissionState.uploading;
  bool get isCancelling => isBusy && (_cancellation?.isCancelled ?? false);
  bool get canCancel =>
      _state == PostSubmissionState.uploading && !isCancelling;

  Future<String?> submit(
    PostFormData Function() readData, {
    Future<void> Function()? prepare,
  }) {
    if (isBusy || _state == PostSubmissionState.success) return Future.value();
    final draft = readData();
    if (!draft.isValid) {
      _fail(PostFailureReason.invalid);
      return Future.value();
    }
    final cancellation = PostCancellation();
    _cancellation = cancellation;
    _failure = null;
    _setState(PostSubmissionState.saving);
    return _inFlight = _submit(draft, readData, prepare, cancellation);
  }

  Future<String?> _submit(
    PostFormData draft,
    PostFormData Function() readData,
    Future<void> Function()? prepare,
    PostCancellation cancellation,
  ) async {
    try {
      final auth = _auth;
      final repository = _repository;
      if (auth == null || repository == null) {
        throw const PostFailure(PostFailureReason.noSession);
      }
      final uid = await auth.ensureSignedIn();
      cancellation.check();
      if (prepare != null) {
        await prepare();
        cancellation.check();
        draft = readData();
      }
      if (!draft.isValid) throw const PostFailure(PostFailureReason.invalid);

      final id = await repository.publish(
        draft,
        authorId: uid,
        cancellation: cancellation,
        onUploadProgress: (progress) {
          if (!cancellation.isCancelled) {
            _setState(PostSubmissionState.uploading, progress: progress);
          }
        },
        onSaving: () => _setState(PostSubmissionState.saving),
      );
      _setState(PostSubmissionState.success);
      return id;
    } on AuthFailure catch (error) {
      _fail(switch (error.reason) {
        AuthFailureReason.noConnection => PostFailureReason.offline,
        AuthFailureReason.anonymousDisabled =>
          PostFailureReason.anonymousDisabled,
        AuthFailureReason.unavailable => PostFailureReason.noSession,
      });
    } on PostFailure catch (error) {
      _fail(error.reason);
    } on Exception {
      _fail(PostFailureReason.save);
    }
    return null;
  }

  Future<bool> cancelUpload() async {
    if (!canCancel) return false;
    _cancellation!.cancel();
    if (!_disposed) notifyListeners();
    await _inFlight;
    return _failure == PostFailureReason.cancelled;
  }

  void _fail(PostFailureReason failure) {
    _failure = failure;
    _setState(PostSubmissionState.error);
  }

  void _setState(PostSubmissionState state, {double? progress}) {
    if (_disposed) return;
    _state = state;
    _progress = progress;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (isBusy) _cancellation?.cancel();
    super.dispose();
  }
}
