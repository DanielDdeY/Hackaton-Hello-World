import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/recognition.dart';

abstract final class RecognitionMapper {
  static Map<String, Object?> create(
    RecognitionDraft draft, {
    required String authorId,
    required String authorName,
    required String period,
  }) {
    final district = draft.districtId?.trim();
    return {
      'authorId': authorId,
      'authorName': authorName,
      'recipientId': draft.recipientId,
      'recipientName': draft.recipientName.trim(),
      if (district != null && district.isNotEmpty) 'districtId': district,
      'message': draft.message,
      'period': period,
      'createdAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    };
  }

  static Recognition? read(String id, Map<String, Object?> data) {
    if (data['schemaVersion'] != 1 ||
        data['authorId'] is! String ||
        data['authorName'] is! String ||
        data['recipientId'] is! String ||
        data['recipientName'] is! String ||
        data['message'] is! String ||
        data['period'] is! String ||
        data['createdAt'] is! Timestamp) {
      return null;
    }
    return Recognition(
      id: id,
      authorId: data['authorId']! as String,
      authorName: data['authorName']! as String,
      recipientId: data['recipientId']! as String,
      recipientName: data['recipientName']! as String,
      districtId: data['districtId'] is String
          ? data['districtId'] as String
          : null,
      message: data['message']! as String,
      period: data['period']! as String,
      createdAt: (data['createdAt']! as Timestamp).toDate(),
    );
  }
}
