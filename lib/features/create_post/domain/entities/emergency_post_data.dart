import '../../../../core/validators/required_field_validator.dart';
import 'post_category.dart';
import 'post_form_data.dart';

enum EmergencyType { robbery, accident, tragedy, health }

final class EmergencyPostData implements PostFormData {
  const EmergencyPostData({
    required this.streetAddress,
    this.type = EmergencyType.robbery,
    this.message,
    this.photoPath,
  });

  final String streetAddress;
  final EmergencyType type;
  final String? message;
  final String? photoPath;

  @override
  PostCategory get category => PostCategory.emergency;

  @override
  bool get isValid => RequiredFieldValidator.isValid(streetAddress);
}
