import 'post_category.dart';

abstract interface class PostFormData {
  PostCategory get category;
  bool get isValid;
}
