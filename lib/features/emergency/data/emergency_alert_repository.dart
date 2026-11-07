import '../domain/emergency_alert.dart';

abstract interface class EmergencyAlertRepository {
  Future<void> create({
    required String alertId,
    required String reporterUid,
    required double latitude,
    required double longitude,
    required String communityId,
  });

  Future<void> close(String alertId, EmergencyAlertStatus status);
}
