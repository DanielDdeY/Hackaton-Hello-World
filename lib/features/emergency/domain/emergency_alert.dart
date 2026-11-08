import 'package:cloud_firestore/cloud_firestore.dart';

const emergencyAlertRadiusMeters = 200;

enum EmergencyAlertStatus { active, cancelled, resolved }

class EmergencyAlert {
  const EmergencyAlert({
    required this.id,
    required this.reporterUid,
    required this.latitude,
    required this.longitude,
    required this.communityId,
    required this.status,
    required this.radiusMeters,
    this.title,
    this.description,
    this.emergencyType,
    this.photoPath,
    this.createdAt,
  });

  final String id;
  final String reporterUid;
  final double latitude;
  final double longitude;
  final String communityId;
  final EmergencyAlertStatus status;
  final int radiusMeters;
  final String? title;
  final String? description;
  final String? emergencyType;
  final String? photoPath;
  final DateTime? createdAt;

  factory EmergencyAlert.fromMap(String id, Map<String, dynamic> data) {
    final location = data['location'] as GeoPoint;
    final status = switch (data['status']) {
      'cancelled' => EmergencyAlertStatus.cancelled,
      'resolved' => EmergencyAlertStatus.resolved,
      _ => EmergencyAlertStatus.active,
    };
    final createdAt = data['createdAt'];
    return EmergencyAlert(
      id: id,
      reporterUid: data['reporterUid'] as String,
      latitude: location.latitude,
      longitude: location.longitude,
      communityId: data['communityId'] as String? ?? '',
      status: status,
      radiusMeters: data['radiusMeters'] as int? ?? emergencyAlertRadiusMeters,
      title: data['title'] as String?,
      description: data['description'] as String?,
      emergencyType: data['emergencyType'] as String?,
      photoPath: data['photoPath'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
