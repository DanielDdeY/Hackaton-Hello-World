enum PhotoPickerFailureReason { cameraDenied, galleryDenied, unavailable }

final class PhotoPickerFailure implements Exception {
  const PhotoPickerFailure(this.reason);

  final PhotoPickerFailureReason reason;
}
