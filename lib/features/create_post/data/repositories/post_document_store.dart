import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/post_failure.dart';

abstract interface class PostDocumentStore {
  String newId();
  Future<void> create(String id, Map<String, Object?> data);
  Future<void> update(String id, Map<String, Object?> data);
}

final class FirebasePostDocumentStore implements PostDocumentStore {
  FirebasePostDocumentStore(FirebaseFirestore firestore)
    : _firestore = firestore,
      _posts = firestore.collection('posts');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _posts;

  @override
  String newId() => _posts.doc().id;

  // Transactions require the server, so an offline create fails instead of
  // being queued after the repository has already rolled back its images.
  @override
  Future<void> create(String id, Map<String, Object?> data) =>
      _firestore.runTransaction((transaction) async {
        final ref = _posts.doc(id);
        final snapshot = await transaction.get(ref);
        if (snapshot.exists) throw const PostFailure(PostFailureReason.save);
        transaction.set(ref, data);
      });

  @override
  Future<void> update(String id, Map<String, Object?> data) =>
      _firestore.runTransaction((transaction) async {
        final ref = _posts.doc(id);
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) throw const PostFailure(PostFailureReason.save);
        transaction.update(ref, data);
      });
}
