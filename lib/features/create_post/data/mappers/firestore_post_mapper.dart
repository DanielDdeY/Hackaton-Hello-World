import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/post_category.dart';
import '../../domain/entities/post_form_data.dart';
import '../../domain/entities/post_location.dart';
import '../../domain/services/image_uploader.dart';
import 'geohash.dart';

enum PostMediaStatus { none, uploading, ready, failed }

abstract final class FirestorePostMapper {
  static const schemaVersion = 2;

  static Map<String, Object?> create(
    PostFormData data, {
    required String postId,
    required String authorId,
    required PostMediaStatus mediaStatus,
    String? authorName,
    List<UploadedPhoto> photos = const [],
  }) => {
    'id': postId,
    'category': data.category == PostCategory.services
        ? 'service'
        : data.category.name,
    'status': 'active',
    'authorId': authorId,
    'authorName': ?authorName,
    'createdAt': FieldValue.serverTimestamp(),
    'schemaVersion': schemaVersion,
    if (data.locationData case final location?) 'location': _location(location),
    'details': data.toMap().map(
      (key, value) =>
          MapEntry(key, value is DateTime ? Timestamp.fromDate(value) : value),
    ),
    ...mediaUpdate(mediaStatus, photos),
  };

  static Map<String, Object?> mediaUpdate(
    PostMediaStatus status,
    List<UploadedPhoto> photos,
  ) => {
    'mediaStatus': status.name,
    'photos': [
      for (final photo in photos)
        {'storagePath': photo.storagePath, 'downloadUrl': photo.downloadUrl},
    ],
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static Map<String, Object?> _location(PostLocation location) {
    final point = location.coordinates;
    return {
      'address': location.address,
      'source': switch (location.source) {
        PostLocationSource.gps => 'gps',
        PostLocationSource.gpsLastKnown => 'gps_last_known',
        PostLocationSource.manual => 'manual',
      },
      if (point != null) ...{
        'geopoint': GeoPoint(point.latitude, point.longitude),
        'geohash': encodeGeohash(point.latitude, point.longitude),
        'isLastKnown': point.isLastKnown,
      },
      if (location.addressEditedByUser) 'addressEditedByUser': true,
    };
  }
}
