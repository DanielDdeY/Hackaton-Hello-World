import '../../../../core/validators/required_field_validator.dart';
import 'location_result.dart';
import 'post_category.dart';
import 'post_form_data.dart';
import 'post_location.dart';

enum EmergencyType {
  robbery,
  accident,
  disaster,
  health,
  fire,
  flood,
  missingPerson,
  other,
}

final class EmergencyPostData implements PostFormData {
  const EmergencyPostData({
    required this.streetAddress,
    this.title,
    this.type = EmergencyType.robbery,
    this.message,
    this.photoPath,
    this.coordinates,
    this.addressEditedByUser = false,
  });

  final String streetAddress;
  final String? title;
  final EmergencyType type;
  final String? message;
  final String? photoPath;
  final LocationResult? coordinates;
  final bool addressEditedByUser;

  @override
  PostCategory get category => PostCategory.emergency;

  @override
  bool get isValid => RequiredFieldValidator.isValid(streetAddress);

  @override
  PostLocation get locationData => PostLocation(
    address: streetAddress,
    coordinates: coordinates,
    addressEditedByUser: addressEditedByUser,
  );

  @override
  List<String> get localPhotoPaths => [?photoPath];

  @override
  Map<String, Object?> toMap() => {
    'type': type.name,
    if (title != null) 'title': title,
    if (message != null) 'message': message,
  };
}
