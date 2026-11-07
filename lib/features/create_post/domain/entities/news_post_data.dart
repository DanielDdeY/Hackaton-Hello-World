import '../../../../core/validators/required_field_validator.dart';
import 'post_category.dart';
import 'post_form_data.dart';
import 'post_location.dart';

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

  @override
  PostLocation? get locationData => null;

  @override
  List<String> get localPhotoPaths => [?photoPath];

  @override
  Map<String, Object?> toMap() => {
    'title': title,
    'content': description,
    'quickCategory': switch (topic) {
      NewsTopic.generalNotice => 'general',
      NewsTopic.lostPet => 'lost_pet',
      NewsTopic.neighborhoodLife => 'neighborhood_life',
      NewsTopic.worksOrOutages => 'service_cuts',
      null => null,
    },
  };
}
