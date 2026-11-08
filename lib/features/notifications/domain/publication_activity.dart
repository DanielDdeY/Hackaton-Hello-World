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

  /// Returns false while this neighbor already has an open request.
  Future<bool> requestService(String postId);

  Stream<List<ServiceRequest>> watchServiceRequests(
    String postId, {
    required bool asProvider,
  });

  Future<void> markServiceDelivered({
    required String postId,
    required String requesterUid,
  });
}

final class ServiceRequest {
  const ServiceRequest({
    required this.requesterUid,
    required this.requesterName,
    this.completionOperationId,
    this.isCompleted = false,
  });

  final String requesterUid;
  final String requesterName;
  final String? completionOperationId;
  final bool isCompleted;
}

enum PublicationActivityFailure implements Exception {
  noSession,
  serviceUnavailable,
  ownService,
  requestUnavailable,
}
