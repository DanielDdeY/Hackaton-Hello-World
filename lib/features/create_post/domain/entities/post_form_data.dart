import 'post_category.dart';
import 'post_location.dart';

abstract interface class PostFormData {
  PostCategory get category;
  bool get isValid;
  PostLocation? get locationData;
  List<String> get localPhotoPaths;

  /// Details without database SDK types.
  Map<String, Object?> toMap();
}
