import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../domain/services/photo_picker.dart';

class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  final Map<String, XFile> _selected = {};

  @override
  Future<String?> pickFromCamera() => _pick(ImageSource.camera);

  @override
  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<String?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (file == null) return null;
    _selected[file.path] = file;
    return file.path;
  }

  @override
  Future<Uint8List> readPhoto(String path) async {
    final selected = _selected[path];
    if (selected == null) {
      throw StateError('No se encontró la foto seleccionada.');
    }
    return selected.readAsBytes();
  }
}
