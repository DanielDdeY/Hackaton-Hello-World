import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/recognition.dart';
import '../domain/services/recognition_repository.dart';
import 'recognition_mapper.dart';

abstract interface class RecognitionDocumentStore {
  Future<void> create(String id, Map<String, Object?> data);

  Future<List<Recognition>> readReceived({
    required String recipientId,
    required String period,
  });
}

final class FirebaseRecognitionDocumentStore
    implements RecognitionDocumentStore {
  FirebaseRecognitionDocumentStore(FirebaseFirestore firestore)
    : _firestore = firestore,
      _recognitions = firestore.collection('recognitions');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _recognitions;

  @override
  Future<void> create(String id, Map<String, Object?> data) async {
    final created = await _firestore.runTransaction((transaction) async {
      final ref = _recognitions.doc(id);
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) return false;
      transaction.set(ref, data);
      return true;
    });
    if (!created) {
      throw const RecognitionFailure(RecognitionFailureReason.duplicate);
    }
  }

  @override
  Future<List<Recognition>> readReceived({
    required String recipientId,
    required String period,
  }) async {
    final snapshot = await _recognitions
        .where('recipientId', isEqualTo: recipientId)
        .where('period', isEqualTo: period)
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.server));
    return [
      for (final doc in snapshot.docs)
        ?RecognitionMapper.read(doc.id, doc.data()),
    ];
  }
}
