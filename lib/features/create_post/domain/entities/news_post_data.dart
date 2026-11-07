import '../../../../core/validators/required_field_validator.dart';
import 'post_category.dart';
import 'post_form_data.dart';

enum NewsTopic { generalNotice, lostPet, neighborhoodLife, worksOrOutages }

final class NewsPostData implements PostFormData {
  const NewsPostData({
    required this.title,
    required this.description,
    this.topic,
    this.photoPath,
  });

  final String title;
  final String description;
  final NewsTopic? topic;
  final String? photoPath;

  @override
  PostCategory get category => PostCategory.news;

  @override
  bool get isValid =>
      RequiredFieldValidator.isValid(title) &&
      RequiredFieldValidator.isValid(description);
}
