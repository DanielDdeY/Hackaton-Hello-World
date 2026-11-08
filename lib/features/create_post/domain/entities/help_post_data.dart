import '../../../../core/validators/required_field_validator.dart';
import 'location_result.dart';
import 'post_category.dart';
import 'post_form_data.dart';
import 'post_location.dart';

final class HelpPostData implements PostFormData {
  const HelpPostData({
    required this.description,
    this.neededBy,
    this.peopleCount,
    this.location,
    this.reward,
    bool? hasReward,
    this.photoPath,
    this.coordinates,
    this.addressEditedByUser = false,
  }) : hasReward = hasReward ?? (reward != null);

  final String description;
  final DateTime? neededBy;
  final int? peopleCount;
  final String? location;
  final String? reward;
  final bool hasReward;
  final String? photoPath;
  final LocationResult? coordinates;
  final bool addressEditedByUser;

  @override
  PostCategory get category => PostCategory.help;

  @override
  bool get isValid => RequiredFieldValidator.isValid(description);

  @override
  PostLocation get locationData => PostLocation(
    address:
        location ??
        (addressEditedByUser
            ? ''
            : coordinates?.address ?? coordinates?.coordinateLabel ?? ''),
    coordinates: coordinates,
    addressEditedByUser: addressEditedByUser,
  );

  @override
  List<String> get localPhotoPaths => [?photoPath];

  @override
  Map<String, Object?> toMap() {
    final count = (peopleCount ?? 1).clamp(1, 300);
    final fichas = count > 2 ? 30 : 15;
    final xp = count > 2 ? 60 : 30;
    final tamano = count > 2 ? 'comunitario' : 'medio';

    return {
      'description': description,
      if (neededBy case final date?)
        'requiredDate': DateTime.utc(date.year, date.month, date.day),
      'peopleNeeded': count,
      'cuposTotales': count,
      'cuposTomados': 0,
      'ayudantes': const <String>[],
      'tamano': tamano,
      'fichasRecompensa': fichas,
      'xpRecompensa': xp,
      'estado': 'abierto',
      if (location != null) 'specificLocation': location,
      'hasReward': hasReward,
      if (hasReward && reward != null) 'rewardDescription': reward,
    };
  }
}
