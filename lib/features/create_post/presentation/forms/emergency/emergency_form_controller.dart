import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../domain/entities/emergency_post_data.dart';
import '../../../domain/services/location_provider.dart';
import '../../../domain/services/photo_picker.dart';

enum EmergencyLocationStatus { loading, ready, unavailable }

class EmergencyFormController extends ChangeNotifier {
  EmergencyFormController({
    required this._locationProvider,
    required this._photoPicker,
  }) {
    unawaited(_loadAddress());
  }

  final LocationProvider _locationProvider;
  final PhotoPicker _photoPicker;
  final streetAddressController = TextEditingController();
  final messageController = TextEditingController();

  EmergencyLocationStatus _locationStatus = EmergencyLocationStatus.loading;
  EmergencyType _type = EmergencyType.robbery;
  bool _messageExpanded = false;
  bool _addressEdited = false;
  bool _disposed = false;
  String? _photoPath;

  EmergencyLocationStatus get locationStatus => _locationStatus;
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

  void markAddressEdited(String _) => _addressEdited = true;

  Future<String?> takePhoto() => _photoPicker.pickFromCamera();

  void setPhotoPath(String? path) {
    _photoPath = path;
    notifyListeners();
  }

  EmergencyPostData get data {
    final message = messageController.text.trim();
    return EmergencyPostData(
      streetAddress: streetAddressController.text.trim(),
      type: _type,
      message: message.isEmpty ? null : message,
      photoPath: _photoPath,
    );
  }

  Future<void> _loadAddress() async {
    String address;
    try {
      address = (await _locationProvider.getCurrentAddress()).trim();
    } on LocationUnavailableException {
      address = '';
    }

    if (_disposed) return;
    _locationStatus = address.isEmpty
        ? EmergencyLocationStatus.unavailable
        : EmergencyLocationStatus.ready;
    if (!_addressEdited && address.isNotEmpty) {
      streetAddressController.text = address;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    streetAddressController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
