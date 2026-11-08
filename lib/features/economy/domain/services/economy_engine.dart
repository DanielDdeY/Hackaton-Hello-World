import '../models/economy_result.dart';

abstract interface class EconomyEngine {
  /// Allocate once per real use, then retain for retries (including app restarts).
  String newOperationId();
  Future<EconomyResult> confirmService({
    required String postId,
    required int rating,
    required String operationId,
  });

  /// Extension point. New sources must define their evidence and server rules.
  /// Callers can never supply their own XP or coin amounts.
  Future<EconomyResult> award({
    required EconomySource source,
    required String sourceId,
    required String operationId,
    int? rating,
  });
}
