import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

import 'emergency_map_repository.dart';

class FirebaseEmergencyMapRepository implements EmergencyMapRepository {
  FirebaseEmergencyMapRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<List<EmergencyMapAlert>> watchAlerts() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.error(
        StateError('Inicia sesión para ver alertas cercanas.'),
      );
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('nearby_emergency_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) {
                final data = document.data();
                final point = data['location'] as GeoPoint;
                return EmergencyMapAlert(
                  id: document.id,
                  location: LatLng(point.latitude, point.longitude),
                  radiusMeters:
                      (data['radiusMeters'] as num?)?.toDouble() ?? 500,
                  title: data['title'] as String? ?? 'Alerta SOS cercana',
                  type: data['emergencyType'] as String? ?? 'Emergencia',
                  status: data['status'] as String? ?? 'active',
                  description: data['description'] as String? ?? '',
                  photoPath: data['photoPath'] as String?,
                );
              })
              .toList(growable: false),
        );
  }
}
