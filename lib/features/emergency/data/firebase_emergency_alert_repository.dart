import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/emergency_alert.dart';
import 'emergency_alert_repository.dart';

class FirebaseEmergencyAlertRepository implements EmergencyAlertRepository {
  FirebaseEmergencyAlertRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> create({
    required String alertId,
    required String reporterUid,
    required double latitude,
    required double longitude,
    required String communityId,
  }) async {
    final alert = _firestore.collection('emergency_alerts').doc(alertId);
    final existing = await alert.get();
    if (existing.exists) {
      if (existing.data()?['reporterUid'] == reporterUid) return;
      throw StateError('El identificador de alerta ya está en uso.');
    }

    await alert.set({
      'reporterUid': reporterUid,
      'location': GeoPoint(latitude, longitude),
      'communityId': communityId,
      'radiusMeters': emergencyAlertRadiusMeters,
      'status': EmergencyAlertStatus.active.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> close(String alertId, EmergencyAlertStatus status) async {
    if (status == EmergencyAlertStatus.active) {
      throw ArgumentError.value(status, 'status', 'Debe cerrar la alerta.');
    }
    await _firestore.collection('emergency_alerts').doc(alertId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
