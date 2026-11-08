import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

import '../../../features/emergency/domain/emergency_alert.dart';
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
    final nearbyAlerts = _firestore
        .collection('users')
        .doc(uid)
        .collection('nearby_emergency_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots();
    final ownAlerts = _firestore
        .collection('emergency_alerts')
        .where('reporterUid', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .snapshots();

    return Stream<List<EmergencyMapAlert>>.multi((controller) {
      List<EmergencyMapAlert> nearby = const [];
      List<EmergencyMapAlert> own = const [];
      void emit() {
        final alerts = <String, EmergencyMapAlert>{
          for (final alert in nearby) alert.id: alert,
          for (final alert in own) alert.id: alert,
        };
        controller.add(alerts.values.toList(growable: false));
      }

      final subscriptions = <StreamSubscription<dynamic>>[
        nearbyAlerts.listen((snapshot) {
          nearby = snapshot.docs
              .map((document) => _toMapAlert(document.id, document.data()))
              .toList(growable: false);
          emit();
        }, onError: controller.addError),
        ownAlerts.listen((snapshot) {
          own = snapshot.docs
              .map((document) => _toMapAlert(document.id, document.data()))
              .toList(growable: false);
          emit();
        }, onError: controller.addError),
      ];
      controller.onCancel = () async {
        await Future.wait(
          subscriptions.map((subscription) => subscription.cancel()),
        );
      };
    });
  }

  EmergencyMapAlert _toMapAlert(String id, Map<String, dynamic> data) {
    final point = data['location'] as GeoPoint;
    return EmergencyMapAlert(
      id: id,
      location: LatLng(point.latitude, point.longitude),
      radiusMeters: emergencyAlertRadiusMeters.toDouble(),
      title: data['title'] as String? ?? 'Alerta SOS cercana',
      type: data['emergencyType'] as String? ?? 'Emergencia',
      status: data['status'] as String? ?? 'active',
      description: data['description'] as String? ?? '',
      photoPath: data['photoPath'] as String?,
    );
  }
}
