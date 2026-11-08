import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:latlong2/latlong.dart';

/// Escucha en tiempo real las alertas SOS propias y las cercanas notificadas.
///
/// Las alertas cercanas viven en `users/{uid}/nearby_emergency_alerts` y las
/// propias en `emergency_alerts`. Se combinan por `alertId` para no duplicar.
class ActiveSosAlerts {
  const ActiveSosAlerts({this.firestore, this.auth});

  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  static bool get isAvailable => Firebase.apps.isNotEmpty;

  Stream<List<Map<String, dynamic>>> watch() {
    if (!isAvailable) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }
    final firestore = this.firestore ?? FirebaseFirestore.instance;
    final uid = (auth ?? FirebaseAuth.instance).currentUser?.uid;
    if (uid == null) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }

    final ownAlerts = firestore
        .collection('emergency_alerts')
        .where('reporterUid', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .snapshots();
    final nearbyAlerts = firestore
        .collection('users')
        .doc(uid)
        .collection('nearby_emergency_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots();

    return Stream<List<Map<String, dynamic>>>.multi((controller) {
      List<Map<String, dynamic>> own = const [];
      List<Map<String, dynamic>> nearby = const [];
      void emit() {
        final byId = <String, Map<String, dynamic>>{
          for (final alert in nearby) alert['alertId'] as String: alert,
          for (final alert in own)
            alert['alertId'] as String: {...alert, 'detailsPending': false},
        };
        controller.add(byId.values.toList(growable: false));
      }

      final subscriptions = <StreamSubscription<dynamic>>[
        ownAlerts.listen((snapshot) {
          own = snapshot.docs
              .map((document) => {...document.data(), 'alertId': document.id})
              .toList(growable: false);
          emit();
        }, onError: controller.addError),
        nearbyAlerts.listen((snapshot) {
          nearby = snapshot.docs
              .map((document) => {...document.data(), 'alertId': document.id})
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
}

List<Map<String, dynamic>> sortSosAlerts(List<Map<String, dynamic>> alerts) {
  final sorted = alerts.toList()
    ..sort((a, b) {
      final aDate = a['createdAt'] as Timestamp?;
      final bDate = b['createdAt'] as Timestamp?;
      return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
        aDate?.millisecondsSinceEpoch ?? 0,
      );
    });
  return sorted;
}

LatLng? sosAlertLocation(Map<String, dynamic> alert) {
  final point = alert['location'] ?? alert['approximateLocation'];
  if (point is GeoPoint) {
    return LatLng(point.latitude, point.longitude);
  }
  return null;
}

String sosRelativeTime(Object? createdAt, {DateTime? now}) {
  if (createdAt is! Timestamp) return 'Ahora';
  final current = now ?? DateTime.now();
  final difference = current.difference(createdAt.toDate());
  if (difference.inSeconds < 60) return 'Ahora';
  if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
  if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
  return 'Hace ${difference.inDays} d';
}
