import 'location_result.dart';

enum PostLocationSource { gps, gpsLastKnown, manual }

final class PostLocation {
  const PostLocation({
    required this.address,
    this.coordinates,
    this.addressEditedByUser = false,
  });

  final String address;
  final LocationResult? coordinates;
  final bool addressEditedByUser;

  PostLocationSource get source {
    if (addressEditedByUser || coordinates == null) {
      return PostLocationSource.manual;
    }
    return coordinates!.isLastKnown
        ? PostLocationSource.gpsLastKnown
        : PostLocationSource.gps;
  }
}
