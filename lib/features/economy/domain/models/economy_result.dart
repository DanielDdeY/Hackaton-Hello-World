enum EconomySource {
  serviceUse,
  completedFavor,
  attendedEvent,
  backpackVerified,
}

enum EconomyFailureReason {
  noSession,
  selfConfirmation,
  monthlyPairLimitReached,
  invalidRating,
  invalidOperation,
  operationConflict,
  serviceNotFound,
  inactiveService,
  userNotFound,
  profileNotReady,
  futurePeriod,
  networkUnavailable,
  permissionDenied,
  simulationActive,
  unsupportedSource,
  unavailable,
}

final class EconomyFailure implements Exception {
  const EconomyFailure(this.reason);
  final EconomyFailureReason reason;
}

final class EconomyResult {
  const EconomyResult({
    required this.confirmationId,
    required this.period,
    required this.slot,
    this.alreadyApplied = false,
    this.clientXp = serviceClientXp,
    this.providerXp = serviceProviderXp,
    this.coins = 0,
  });

  static const serviceClientXp = 15;
  static const serviceProviderXp = 25;
  static const eventXp = 10;
  static const eventCoins = 3;

  final String confirmationId;
  final String period;
  final int slot;
  final bool alreadyApplied;
  final int clientXp;
  final int providerXp;
  final int coins;
}
