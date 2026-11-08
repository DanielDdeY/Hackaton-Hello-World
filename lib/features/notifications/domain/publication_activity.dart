enum PublicationActivityKind { helpOffer, eventAttendance, serviceRequest }

final class PublicationActivity {
  const PublicationActivity({
    required this.kind,
    required this.actorName,
    required this.postTitle,
    required this.occurredAt,
  });

  final PublicationActivityKind kind;
  final String actorName;
  final String postTitle;
  final DateTime? occurredAt;
}

abstract interface class PublicationActivityRepository {
  Stream<List<PublicationActivity>> watchReceived();

  /// Returns false when this neighbor already requested the service.
  Future<bool> requestService(String postId);
}

enum PublicationActivityFailure implements Exception {
  noSession,
  serviceUnavailable,
  ownService,
}
