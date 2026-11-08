import '../../../../core/validators/required_field_validator.dart';
import 'post_category.dart';
import 'post_form_data.dart';
import 'post_location.dart';

final class EventPostData implements PostFormData {
  const EventPostData({
    required this.title,
    required this.place,
    required this.startsAt,
    this.attendees,
    this.description = '',
  });

  final String title;
  final String place;
  final DateTime? startsAt;
  final int? attendees;
  final String description;

  @override
  PostCategory get category => PostCategory.event;

  @override
  bool get isValid =>
      RequiredFieldValidator.isValid(title) &&
      RequiredFieldValidator.isValid(place) &&
      startsAt?.isAfter(DateTime.now()) == true &&
      (attendees ?? 0) >= 0;

  @override
  PostLocation? get locationData => null;

  @override
  List<String> get localPhotoPaths => const [];

  @override
  Map<String, Object?> toMap() => {
    'title': title.trim(),
    'place': place.trim(),
    'startsAt': startsAt,
    'attendees': ?attendees,
    if (description.trim().isNotEmpty) 'description': description.trim(),
  };
}
