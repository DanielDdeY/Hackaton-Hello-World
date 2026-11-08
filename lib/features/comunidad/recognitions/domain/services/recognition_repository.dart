import '../entities/recognition.dart';

abstract interface class RecognitionRepository {
  Future<void> send(RecognitionDraft draft);

  Future<WrappedRecognitions> getForWrapped({
    required String recipientId,
    String? period,
  });
}

final class WrappedRecognitions {
  WrappedRecognitions.open(String activePeriod, List<Recognition> recognitions)
    : period = activePeriod,
      isOpen = true,
      items = List.unmodifiable(recognitions);

  const WrappedRecognitions.closed()
    : period = null,
      isOpen = false,
      items = const [];

  final String? period;
  final bool isOpen;
  final List<Recognition> items;
}

enum RecognitionFailureReason {
  noSession,
  offline,
  permissionDenied,
  duplicate,
  invalid,
  unavailable,
}

final class RecognitionFailure implements Exception {
  const RecognitionFailure(this.reason);

  final RecognitionFailureReason reason;
}
