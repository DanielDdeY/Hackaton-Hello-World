import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../create_post/domain/entities/emergency_post_data.dart';
import '../../create_post/domain/entities/post_failure.dart';
import '../../create_post/domain/entities/post_form_data.dart';
import '../../create_post/domain/services/photo_picker.dart';
import '../../create_post/domain/services/post_cancellation.dart';
import '../../create_post/domain/services/post_repository.dart';

class FirebaseEmergencyPostRepository implements PostRepository {
  FirebaseEmergencyPostRepository({
    required this.alertId,
    required this.photoPicker,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  static const _maxPhotoBytes = 5 * 1024 * 1024;
  final String alertId;
  final PhotoPicker photoPicker;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<String> publish(
    PostFormData formData, {
    required String authorId,
    required PostCancellation cancellation,
    void Function(double progress)? onUploadProgress,
    void Function()? onSaving,
  }) async {
    if (formData is! EmergencyPostData || !formData.isValid) {
      throw const PostFailure(PostFailureReason.invalid);
    }
    final title = formData.title?.trim() ?? '';
    if (title.isEmpty) throw const PostFailure(PostFailureReason.invalid);
    cancellation.check();

    final alertRef = _firestore.collection('emergency_alerts').doc(alertId);
    final alertSnapshot = await alertRef.get();
    if (!alertSnapshot.exists ||
        alertSnapshot.data()?['reporterUid'] != authorId) {
      throw StateError('No se encontró una alerta SOS propia para publicar.');
    }
    if (alertSnapshot.data()?['status'] != 'active') {
      throw StateError(
        'La alerta ya no está activa y no admite nuevos detalles.',
      );
    }

    final communityId = alertSnapshot.data()?['communityId'] as String? ?? '';
    final location = alertSnapshot.data()?['location'] as GeoPoint?;
    if (communityId.isEmpty || location == null) {
      throw StateError('La alerta no tiene distrito o ubicación válida.');
    }

    final postRef = _firestore.collection('community_posts').doc(alertId);
    final existingPost = await postRef.get();
    if (existingPost.exists) {
      if (existingPost.data()?['authorUid'] == authorId) return alertId;
      throw StateError('Ya existe una publicación para esta alerta.');
    }

    String? photoPath;
    Reference? uploadedPhoto;
    try {
      if (formData.photoPath != null) {
        final bytes = await photoPicker.readPhoto(formData.photoPath!);
        if (bytes.isEmpty) {
          throw StateError('No se pudo leer la foto seleccionada. Elige otra.');
        }
        if (bytes.length > _maxPhotoBytes) {
          throw StateError('La foto supera el límite de 5 MB.');
        }
        final contentType = _imageContentType(bytes);
        if (contentType == null) {
          throw StateError('La foto debe estar en formato JPEG, PNG o WebP.');
        }
        cancellation.check();
        uploadedPhoto = _storage.ref().child(
          'incident_photos/$authorId/$alertId/photo',
        );
        final task = uploadedPhoto.putData(
          bytes,
          SettableMetadata(
            contentType: contentType,
            customMetadata: {'communityId': communityId},
          ),
        );
        void cancelUpload() {
          unawaited(task.cancel());
        }

        cancellation.addListener(cancelUpload);
        final progress = task.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            onUploadProgress?.call(
              snapshot.bytesTransferred / snapshot.totalBytes,
            );
          }
        });
        try {
          await task;
        } catch (_) {
          cancellation.check();
          rethrow;
        } finally {
          cancellation.removeListener(cancelUpload);
          await progress.cancel();
        }
        cancellation.check();
        photoPath = uploadedPhoto.fullPath;
      }

      cancellation.check();
      onSaving?.call();
      final approximateLocation = GeoPoint(
        (location.latitude * 1000).round() / 1000,
        (location.longitude * 1000).round() / 1000,
      );
      final batch = _firestore.batch();
      batch.set(postRef, {
        'alertId': alertId,
        'authorUid': authorId,
        'communityId': communityId,
        'category': 'emergency',
        'emergencyType': formData.type.name,
        'title': title,
        'description': formData.message ?? formData.streetAddress,
        'photoPath': photoPath,
        'approximateLocation': approximateLocation,
        'priority': 1,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(alertRef, {
        'title': title,
        'description': formData.message ?? formData.streetAddress,
        'emergencyType': formData.type.name,
        'photoPath': photoPath,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on Exception {
      if (uploadedPhoto != null) {
        try {
          await uploadedPhoto.delete();
        } on FirebaseException catch (error) {
          if (error.code != 'object-not-found') rethrow;
        }
      }
      rethrow;
    }
    return alertId;
  }

  String? _imageContentType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }
}
