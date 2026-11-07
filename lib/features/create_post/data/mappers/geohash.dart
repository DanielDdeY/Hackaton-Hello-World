const _alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';

String encodeGeohash(double latitude, double longitude) {
  var south = -90.0;
  var north = 90.0;
  var west = -180.0;
  var east = 180.0;
  final result = StringBuffer();
  var value = 0;

  for (var bit = 0; bit < 45; bit++) {
    value <<= 1;
    if (bit.isEven) {
      final middle = (west + east) / 2;
      if (longitude >= middle) {
        west = middle;
        value |= 1;
      } else {
        east = middle;
      }
    } else {
      final middle = (south + north) / 2;
      if (latitude >= middle) {
        south = middle;
        value |= 1;
      } else {
        north = middle;
      }
    }
    if (bit % 5 == 4) {
      result.write(_alphabet[value]);
      value = 0;
    }
  }
  return result.toString();
}
