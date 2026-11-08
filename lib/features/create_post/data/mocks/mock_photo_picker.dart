import 'dart:typed_data';

import '../../domain/services/photo_picker.dart';

final class MockPhotoPicker implements PhotoPicker {
  const MockPhotoPicker();

  @override
  Future<String?> pickFromCamera() => _pickMockPhoto();

  @override
  Future<String?> pickFromGallery() => _pickMockPhoto();

  @override
  Future<Uint8List> readPhoto(String path) async => Uint8List(0);

  Future<String> _pickMockPhoto() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return 'mock/photo.jpg';
  }
}
