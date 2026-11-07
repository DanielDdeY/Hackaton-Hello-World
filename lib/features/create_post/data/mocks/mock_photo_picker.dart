import '../../domain/services/photo_picker.dart';

final class MockPhotoPicker implements PhotoPicker {
  const MockPhotoPicker();

  @override
  Future<String?> pickFromCamera() => _pickMockPhoto();

  @override
  Future<String?> pickFromGallery() => _pickMockPhoto();

  Future<String> _pickMockPhoto() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return 'mock/photo.jpg';
  }
}
