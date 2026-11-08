import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../../../create_post/domain/services/auth_gateway.dart';
import '../../../create_post/domain/services/post_author_name_resolver.dart';
import '../../../economy/domain/services/period_provider.dart';
import '../domain/entities/recognition.dart';
import '../domain/services/recognition_repository.dart';
import '../domain/services/wrapped_window_policy.dart';
import 'recognition_document_store.dart';
import 'recognition_mapper.dart';

final class FirestoreRecognitionRepository implements RecognitionRepository {
  FirestoreRecognitionRepository({
    required this._auth,
    required this._authorNames,
    required this._documents,
    required this._periods,
    this._window = const WrappedWindowPolicy(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AuthGateway _auth;
  final PostAuthorNameResolver _authorNames;
  final RecognitionDocumentStore _documents;
  final PeriodProvider _periods;
  final WrappedWindowPolicy _window;
  final DateTime Function() _clock;

  @override
  Future<void> send(RecognitionDraft draft) async {
    final authorId = _requireSession();
    if (!draft.isValid || draft.recipientId == authorId) {
      throw const RecognitionFailure(RecognitionFailureReason.invalid);
    }
    try {
      final name = await _authorNames.resolve(authorId);
      if (_auth.currentUid != authorId) {
        throw const RecognitionFailure(RecognitionFailureReason.noSession);
      }
      final period = _periods.currentPeriod;
      await _documents.create(
        '${period}_${authorId}_${draft.recipientId}',
        RecognitionMapper.create(
          draft,
          authorId: authorId,
          authorName: name,
          period: period,
        ),
      );
    } on TimeoutException {
      throw const RecognitionFailure(RecognitionFailureReason.offline);
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<WrappedRecognitions> getForWrapped({
    required String recipientId,
    String? period,
  }) async {
    final activePeriod = _window.activePeriod(_clock());
    if (activePeriod == null || (period != null && period != activePeriod)) {
      return const WrappedRecognitions.closed();
    }
    if (_requireSession() != recipientId) {
      throw const RecognitionFailure(RecognitionFailureReason.permissionDenied);
    }
    try {
      final items = await _documents.readReceived(
        recipientId: recipientId,
        period: activePeriod,
      );
      if (_auth.currentUid != recipientId) {
        throw const RecognitionFailure(RecognitionFailureReason.noSession);
      }
      return WrappedRecognitions.open(activePeriod, items);
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  String _requireSession() {
    final uid = _auth.currentUid;
    if (uid == null || uid.isEmpty) {
      throw const RecognitionFailure(RecognitionFailureReason.noSession);
    }
    return uid;
  }

  static RecognitionFailure _failure(FirebaseException error) =>
      RecognitionFailure(switch (error.code) {
        'unauthenticated' => RecognitionFailureReason.noSession,
        'unavailable' ||
        'deadline-exceeded' ||
        'network-request-failed' => RecognitionFailureReason.offline,
        'permission-denied' => RecognitionFailureReason.permissionDenied,
        'already-exists' => RecognitionFailureReason.duplicate,
        _ => RecognitionFailureReason.unavailable,
      });
}
