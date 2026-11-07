enum PostFailureReason {
  invalid,
  noSession,
  anonymousDisabled,
  offline,
  timeout,
  tooLarge,
  invalidPhoto,
  permissionDenied,
  cancelled,
  upload,
  save,
  cleanup,
}

final class PostFailure implements Exception {
  const PostFailure(this.reason);

  final PostFailureReason reason;
}
