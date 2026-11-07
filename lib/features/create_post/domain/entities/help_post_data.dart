import '../../../../core/validators/required_field_validator.dart';
import 'post_category.dart';
import 'post_form_data.dart';

final class HelpPostData implements PostFormData {
  const HelpPostData({
    required this.description,
    this.neededBy,
    this.peopleCount,
    this.location,
    this.reward,
    this.photoPath,
  });

  final String description;
  final DateTime? neededBy;
  final int? peopleCount;
  final String? location;
  final String? reward;
  final String? photoPath;

  @override
  PostCategory get category => PostCategory.help;

  @override
  bool get isValid => RequiredFieldValidator.isValid(description);
}
