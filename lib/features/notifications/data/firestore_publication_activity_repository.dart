import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../create_post/domain/services/auth_gateway.dart';
import '../domain/publication_activity.dart';

final class FirestorePublicationActivityRepository
    implements PublicationActivityRepository {
  const FirestorePublicationActivityRepository({
    required this._firestore,
    required this._auth,
  });

  final FirebaseFirestore _firestore;
  final AuthGateway _auth;

  @override
  Stream<List<PublicationActivity>> watchReceived() {
    final uid = _auth.currentUid;
    if (uid == null || uid.isEmpty) {
      return Stream.error(PublicationActivityFailure.noSession);
    }
    return _ReceivedActivityFeed(_firestore, _auth, uid).stream;
  }

  @override
  Future<bool> requestService(String postId) async {
    final uid = _auth.currentUid;
    if (uid == null || uid.isEmpty) throw PublicationActivityFailure.noSession;

    final post = _firestore.collection('posts').doc(postId);
    final request = post.collection('serviceRequests').doc(uid);
    final outcome = await _firestore.runTransaction((transaction) async {
      final postData = (await transaction.get(post)).data();
      if (postData?['category'] != 'service' ||
          postData?['status'] != 'active' ||
          _text(postData?['authorId']) == null) {
        return _ServiceRequestOutcome.unavailable;
      }
      if (postData!['authorId'] == uid) {
        return _ServiceRequestOutcome.ownService;
      }
      final current = (await transaction.get(request)).data();
      if (current != null && current['completedAt'] is! Timestamp) {
        return _ServiceRequestOutcome.duplicate;
      }

      final profile = await transaction.get(
        _firestore.collection('users').doc(uid),
      );
      final name =
          _text(profile.data()?['name']) ?? _text(_auth.currentDisplayName);
      transaction.set(request, {
        'requestedAt': FieldValue.serverTimestamp(),
        if (name != null && name.runes.length <= 100) 'requesterName': name,
      });
      return _ServiceRequestOutcome.created;
    });
    return switch (outcome) {
      _ServiceRequestOutcome.created => true,
      _ServiceRequestOutcome.duplicate => false,
      _ServiceRequestOutcome.unavailable =>
        throw PublicationActivityFailure.serviceUnavailable,
      _ServiceRequestOutcome.ownService =>
        throw PublicationActivityFailure.ownService,
    };
  }

  @override
  Stream<List<ServiceRequest>> watchServiceRequests(
    String postId, {
    required bool asProvider,
  }) {
    final uid = _auth.currentUid;
    if (uid == null || uid.isEmpty) {
      return Stream.error(PublicationActivityFailure.noSession);
    }
    final requests = _firestore
        .collection('posts')
        .doc(postId)
        .collection('serviceRequests');
    if (asProvider) {
      return requests
          .orderBy('requestedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => [
              for (final doc in snapshot.docs) _readRequest(doc.id, doc.data()),
            ],
          );
    }
    return requests.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      return [if (data != null) _readRequest(uid, data)];
    });
  }

  static ServiceRequest _readRequest(String uid, Map<String, dynamic> data) =>
      ServiceRequest(
        requesterUid: uid,
        requesterName: _text(data['requesterName']) ?? 'Vecino',
        completionOperationId: data['providerCompletedAt'] is Timestamp
            ? _text(data['completionOperationId'])
            : null,
        isCompleted: data['completedAt'] is Timestamp,
      );

  @override
  Future<void> markServiceDelivered({
    required String postId,
    required String requesterUid,
  }) async {
    final uid = _auth.currentUid;
    if (uid == null || uid.isEmpty) throw PublicationActivityFailure.noSession;
    final post = _firestore.collection('posts').doc(postId);
    final requests = post.collection('serviceRequests');
    final request = requests.doc(requesterUid);
    final operationId = requests.doc().id;
    final failure = await _firestore
        .runTransaction<PublicationActivityFailure?>((transaction) async {
          final data = (await transaction.get(post)).data();
          if (data?['category'] != 'service' ||
              data?['status'] != 'active' ||
              data?['authorId'] != uid ||
              requesterUid == uid) {
            return PublicationActivityFailure.serviceUnavailable;
          }
          final current = (await transaction.get(request)).data();
          if (current == null) {
            return PublicationActivityFailure.requestUnavailable;
          }
          if (current['providerCompletedAt'] is Timestamp) return null;
          transaction.update(request, {
            'providerCompletedAt': FieldValue.serverTimestamp(),
            'completionOperationId': operationId,
          });
          return null;
        });
    if (failure != null) throw failure;
  }
}

enum _ServiceRequestOutcome { created, duplicate, unavailable, ownService }

class _ReceivedActivityFeed {
  _ReceivedActivityFeed(this._firestore, this._auth, this._uid);

  final FirebaseFirestore _firestore;
  final AuthGateway _auth;
  final String _uid;
  final _posts = <String, _ActivitySource>{};
  final _entries =
      <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
  final _subscriptions =
      <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
  final _names = <String, Future<String>>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _postSubscription;
  bool _active = true;
  int _revision = 0;

  late final _controller = StreamController<List<PublicationActivity>>(
    onListen: _listen,
    onCancel: _cancel,
  );

  Stream<List<PublicationActivity>> get stream => _controller.stream;
  bool get _canEmit => _active && _auth.currentUid == _uid;

  void _listen() {
    _postSubscription = _firestore
        .collection('posts')
        .where('authorId', isEqualTo: _uid)
        .snapshots()
        .listen(_replacePosts, onError: _reportError);
  }

  void _replacePosts(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (!_canEmit) return;
    final next = {
      for (final doc in snapshot.docs) doc.id: ?_ActivitySource.read(doc),
    };
    for (final id in _posts.keys) {
      if (_posts[id]?.kind != next[id]?.kind) {
        unawaited(_subscriptions.remove(id)?.cancel());
        _entries.remove(id);
      }
    }
    _posts
      ..clear()
      ..addAll(next);

    for (final source in _posts.values) {
      _subscriptions.putIfAbsent(source.id, () => _watchSource(source));
    }
    unawaited(_emit());
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _watchSource(
    _ActivitySource source,
  ) {
    final collection = _firestore
        .collection('posts')
        .doc(source.id)
        .collection(source.collection);
    final query = source.kind == PublicationActivityKind.eventAttendance
        ? collection.where('response', isEqualTo: 'going')
        : collection;
    return query.snapshots().listen((snapshot) {
      if (!_canEmit || _posts[source.id]?.kind != source.kind) return;
      _entries[source.id] = snapshot.docs
          .where((doc) => doc.id != _uid)
          .toList();
      unawaited(_emit());
    }, onError: _reportError);
  }

  Future<void> _emit() async {
    final revision = ++_revision;
    if (!_canEmit || !_posts.keys.every(_entries.containsKey)) return;
    final items = await Future.wait([
      for (final source in _posts.values)
        for (final doc in _entries[source.id]!) _readActivity(source, doc),
    ]);
    if (!_canEmit || revision != _revision) return;
    items.sort(
      (a, b) => (b.occurredAt?.millisecondsSinceEpoch ?? 0).compareTo(
        a.occurredAt?.millisecondsSinceEpoch ?? 0,
      ),
    );
    _controller.add(List.unmodifiable(items));
  }

  Future<PublicationActivity> _readActivity(
    _ActivitySource source,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final (nameField, timeField) = switch (source.kind) {
      PublicationActivityKind.helpOffer => ('helperName', 'offeredAt'),
      PublicationActivityKind.eventAttendance => (null, 'updatedAt'),
      PublicationActivityKind.serviceRequest => (
        'requesterName',
        'requestedAt',
      ),
    };
    final name =
        _text(data[nameField]) ??
        await _names.putIfAbsent(doc.id, () => _readName(doc.id));
    final time = data[timeField];
    return PublicationActivity(
      kind: source.kind,
      actorName: name,
      postTitle: source.title,
      occurredAt: time is Timestamp ? time.toDate() : null,
    );
  }

  Future<String> _readName(String uid) async {
    try {
      final profile = await _firestore.collection('users').doc(uid).get();
      final name = _text(profile.data()?['name']);
      if (name != null) return name;
    } on FirebaseException {
      // Older accounts may not have a readable public profile yet.
    }
    final suffix = uid.length > 6 ? uid.substring(uid.length - 6) : uid;
    return 'Vecino · $suffix';
  }

  void _reportError(Object error, StackTrace stack) {
    _revision++;
    if (_canEmit) _controller.addError(error, stack);
  }

  Future<void> _cancel() async {
    _active = false;
    await _postSubscription?.cancel();
    await Future.wait(_subscriptions.values.map((item) => item.cancel()));
  }
}

class _ActivitySource {
  const _ActivitySource(this.id, this.kind, this.title);

  final String id;
  final PublicationActivityKind kind;
  final String title;

  String get collection => switch (kind) {
    PublicationActivityKind.helpOffer => 'helpOffers',
    PublicationActivityKind.eventAttendance => 'attendance',
    PublicationActivityKind.serviceRequest => 'serviceRequests',
  };

  static _ActivitySource? read(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final kind = switch (data['category']) {
      'help' => PublicationActivityKind.helpOffer,
      'event' => PublicationActivityKind.eventAttendance,
      'service' => PublicationActivityKind.serviceRequest,
      _ => null,
    };
    if (kind == null) return null;
    final details = data['details'];
    final title = details is Map
        ? _text(details['title']) ??
              (kind == PublicationActivityKind.helpOffer
                  ? _text(details['description'])
                  : null)
        : null;
    return _ActivitySource(doc.id, kind, title ?? 'Publicación del barrio');
  }
}

String? _text(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}
