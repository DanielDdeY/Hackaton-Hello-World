import 'package:flutter/widgets.dart';

import '../../../domain/entities/help_post_data.dart';
import '../../../domain/services/photo_picker.dart';

class HelpFormController extends ChangeNotifier {
  HelpFormController({required this._photoPicker});

  final PhotoPicker _photoPicker;
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
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
    if (count != null && count < 1) return;
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
    neededBy: _neededBy,
    peopleCount: _peopleCount,
    location: _optionalText(locationController.text),
    reward: _rewardEnabled ? _optionalText(rewardController.text) : null,
    photoPath: _photoPath,
  );

  static String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    descriptionController.dispose();
    locationController.dispose();
    rewardController.dispose();
    super.dispose();
  }
}
