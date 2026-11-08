import 'package:flutter/widgets.dart';

import '../../../domain/entities/help_post_data.dart';
import '../../../domain/services/location_provider.dart';
import '../../../domain/services/photo_picker.dart';
import '../../location/post_location_capture.dart';

class HelpFormController extends ChangeNotifier with PostLocationCapture {
  HelpFormController({
    required this._photoPicker,
    required LocationProvider locationProvider,
  }) {
    locationReady = captureLocation(locationProvider);
  }

  final PhotoPicker _photoPicker;
  late final Future<void> locationReady;
  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();
  TextEditingController get locationController => addressController;
  final rewardController = TextEditingController();

  bool _detailsExpanded = false;
  bool _rewardEnabled = false;
  DateTime? _neededBy;
  int? _peopleCount;
  String? _photoPath;

  bool get detailsExpanded => _detailsExpanded;
  bool get rewardEnabled => _rewardEnabled;
  DateTime? get neededBy => _neededBy;
  int? get peopleCount => _peopleCount;
  String? get photoPath => _photoPath;

  void setDetailsExpanded(bool expanded) {
    _detailsExpanded = expanded;
    notifyListeners();
  }

  void setRewardEnabled(bool enabled) {
    _rewardEnabled = enabled;
    if (!enabled) rewardController.clear();
    notifyListeners();
  }

  void setNeededBy(DateTime? date) {
    _neededBy = date;
    notifyListeners();
  }

  void setPeopleCount(int? count) {
    if (count != null && (count < 1 || count > 300)) return;
    _peopleCount = count;
    notifyListeners();
  }

  Future<String?> takePhoto() => _photoPicker.pickFromCamera();

  Future<String?> choosePhoto() => _photoPicker.pickFromGallery();

  void setPhotoPath(String? path) {
    _photoPath = path;
    notifyListeners();
  }

  HelpPostData get data => HelpPostData(
    description: descriptionController.text.trim(),
    contactPhone: phoneController.text.trim(),
    neededBy: _neededBy,
    peopleCount: _peopleCount,
    location: _optionalText(locationController.text),
    reward: _rewardEnabled ? _optionalText(rewardController.text) : null,
    hasReward: _rewardEnabled,
    photoPath: _photoPath,
    coordinates: coordinates,
    addressEditedByUser: addressEditedByUser,
  );

  static String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    descriptionController.dispose();
    phoneController.dispose();
    rewardController.dispose();
    super.dispose();
  }
}
