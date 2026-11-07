abstract interface class PhotoPicker {
  /// Returns the selected image path or null when the user cancels.
  Future<String?> pickFromCamera();

  /// Returns the selected image path or null when the user cancels.
  Future<String?> pickFromGallery();
}
