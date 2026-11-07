import 'package:flutter/widgets.dart';

import '../../../domain/entities/news_post_data.dart';
import '../../../domain/services/photo_picker.dart';

class NewsFormController extends ChangeNotifier {
  NewsFormController({required this._photoPicker});

  final PhotoPicker _photoPicker;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  NewsTopic? _topic;
  String? _photoPath;

  NewsTopic? get topic => _topic;
  String? get photoPath => _photoPath;

  void setTopic(NewsTopic? topic) {
    _topic = topic;
    notifyListeners();
  }

  Future<String?> takePhoto() => _photoPicker.pickFromCamera();

  Future<String?> choosePhoto() => _photoPicker.pickFromGallery();

  void setPhotoPath(String? path) {
    _photoPath = path;
    notifyListeners();
  }

  NewsPostData get data => NewsPostData(
    title: titleController.text.trim(),
    description: descriptionController.text.trim(),
    topic: _topic,
    photoPath: _photoPath,
  );

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
