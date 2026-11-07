import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/photo_limits.dart';
import '../../../../core/errors/photo_picker_failure.dart';
import '../../domain/services/photo_picker.dart';

final class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<String?> pickFromCamera() => _pick(ImageSource.camera);

  @override
  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<String?> _pick(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: photoMaxWidth,
        maxHeight: photoMaxHeight,
        imageQuality: photoImageQuality,
        requestFullMetadata: false,
      );
      return photo?.path;
    } on PlatformException catch (error) {
      throw PhotoPickerFailure(switch (error.code) {
        'camera_access_denied' ||
        'camera_access_restricted' ||
        'camera_access_denied_without_prompt' =>
          PhotoPickerFailureReason.cameraDenied,
        'photo_access_denied' ||
        'photo_access_restricted' ||
        'photo_access_denied_without_prompt' =>
          PhotoPickerFailureReason.galleryDenied,
        _ => PhotoPickerFailureReason.unavailable,
      });
    } on UnsupportedError {
      throw const PhotoPickerFailure(PhotoPickerFailureReason.unavailable);
    }
  }
}
