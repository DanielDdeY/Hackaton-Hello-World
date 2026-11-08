import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/economy_result.dart';
import '../domain/repositories/economy_store.dart';

final class FirestoreEconomyStore implements EconomyStore {
  FirestoreEconomyStore(this.firestore);
  final FirebaseFirestore firestore;

  @override
  String newOperationId() =>
      firestore.collection('serviceConfirmations').doc().id;
  @override
  Object get serverTimestamp => FieldValue.serverTimestamp();

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(EconomyTransaction tx) action,
  ) async {
    try {
      return await firestore.runTransaction(
        (tx) => action(_FirestoreEconomyTransaction(firestore, tx)),
      );
    } on FirebaseException catch (error) {
      throw EconomyFailure(switch (error.code) {
        'unavailable' ||
        'deadline-exceeded' => EconomyFailureReason.networkUnavailable,
        'permission-denied' => EconomyFailureReason.permissionDenied,
        'unauthenticated' => EconomyFailureReason.noSession,
        _ => EconomyFailureReason.unavailable,
      });
    }
  }
}

final class _FirestoreEconomyTransaction implements EconomyTransaction {
  _FirestoreEconomyTransaction(this.firestore, this.transaction);
  final FirebaseFirestore firestore;
  final Transaction transaction;

  @override
  Future<Map<String, dynamic>?> get(String path) async =>
      (await transaction.get(firestore.doc(path))).data();

  @override
  void create(String path, Map<String, dynamic> data) {
    // The server rules only permit creation of immutable receipts/movements.
    transaction.set(firestore.doc(path), data);
  }

  @override
  void update(String path, Map<String, dynamic> data) {
    transaction.update(firestore.doc(path), data);
  }
}
