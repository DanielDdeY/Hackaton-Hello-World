import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../domain/entities/emergency_post_data.dart';
import '../../../domain/services/location_provider.dart';
import '../../../domain/services/photo_picker.dart';
import '../../location/post_location_capture.dart';

class EmergencyFormController extends ChangeNotifier with PostLocationCapture {
  EmergencyFormController({
    required LocationProvider locationProvider,
    required this._photoPicker,
  }) {
    unawaited(captureLocation(locationProvider));
  }

  final PhotoPicker _photoPicker;
  TextEditingController get streetAddressController => addressController;
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  EmergencyType _type = EmergencyType.robbery;
  bool _messageExpanded = false;
  String? _photoPath;

  EmergencyType get type => _type;
  bool get messageExpanded => _messageExpanded;
  String? get photoPath => _photoPath;

  void selectType(EmergencyType type) {
    if (_type == type) return;
    _type = type;
    notifyListeners();
  }

  void setMessageExpanded(bool expanded) {
    _messageExpanded = expanded;
    notifyListeners();
  }

  Future<String?> takePhoto() => _photoPicker.pickFromCamera();

  void setPhotoPath(String? path) {
    _photoPath = path;
    notifyListeners();
  }

  EmergencyPostData get data {
    final message = messageController.text.trim();
    return EmergencyPostData(
      streetAddress: streetAddressController.text.trim(),
      title: titleController.text.trim().isEmpty
          ? null
          : titleController.text.trim(),
      type: _type,
      message: message.isEmpty ? null : message,
      photoPath: _photoPath,
      coordinates: coordinates,
      addressEditedByUser: addressEditedByUser,
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
