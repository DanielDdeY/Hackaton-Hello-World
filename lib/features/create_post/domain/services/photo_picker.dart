import 'dart:typed_data';

abstract interface class PhotoPicker {
  /// Returns the selected image path or null when the user cancels.
  Future<String?> pickFromCamera();

  /// Returns the selected image path or null when the user cancels.
  Future<String?> pickFromGallery();

  Future<Uint8List> readPhoto(String path);
}
