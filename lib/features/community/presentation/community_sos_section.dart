import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class CommunitySosSection extends StatelessWidget {
  const CommunitySosSection({super.key, this.alerts});

  final Stream<List<Map<String, dynamic>>>? alerts;

  Stream<List<Map<String, dynamic>>> _watchAlerts() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    final firestore = FirebaseFirestore.instance;
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
          for (final alert in own) alert['alertId'] as String: alert,
        };
        controller.add(byId.values.toList(growable: false));
      }

      final subscriptions = <StreamSubscription<dynamic>>[
        ownAlerts.listen((snapshot) {
          own = snapshot.docs
              .map(
                (document) => {
                  ...document.data(),
                  'alertId': document.id,
                  'detailsPending': false,
                },
              )
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

  @override
  Widget build(BuildContext context) {
    final alertsStream =
        alerts ??
        (Firebase.apps.isEmpty
            ? Stream.value(const <Map<String, dynamic>>[])
            : _watchAlerts());

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: alertsStream,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xffb71c1c)),
                SizedBox(width: 8),
                Text(
                  'Alertas SOS cercanas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (snapshot.hasError)
              const Text('No se pudieron cargar las alertas SOS.')
            else if (!snapshot.hasData)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.data!.isEmpty)
              const Text('No hay alertas SOS activas en este momento.')
            else
              for (final alert in _sorted(snapshot.data!)) ...[
                _SosAlertCard(alert: alert),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> alerts) {
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
}

class _SosAlertCard extends StatelessWidget {
  const _SosAlertCard({required this.alert});

  final Map<String, dynamic> alert;

  @override
  Widget build(BuildContext context) {
    final type = (alert['emergencyType'] as String? ?? 'emergencia')
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .toUpperCase();
    final title = alert['title'] as String? ?? 'Alerta SOS cercana';
    final description = alert['description'] as String? ?? '';
    final photoPath = alert['photoPath'] as String?;
    final detailsPending = alert['detailsPending'] == true;

    return Card(
      color: const Color(0xfffff1f0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xffc62828), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_rounded, color: Color(0xffb71c1c)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SOS · $type',
                    style: const TextStyle(
                      color: Color(0xffb71c1c),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (detailsPending) ...[
              const SizedBox(height: 6),
              const Text('Se están completando los detalles de la alerta.'),
            ],
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(description),
            ],
            if (photoPath != null) ...[
              const SizedBox(height: 10),
              _SosPhoto(path: photoPath),
            ],
          ],
        ),
      ),
    );
  }
}

class _SosPhoto extends StatelessWidget {
  const _SosPhoto({required this.path});

  final String path;

  Future<Uint8List?> _load() =>
      FirebaseStorage.instance.ref(path).getData(5 * 1024 * 1024);

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _load(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text('No se pudo cargar la foto del reporte.');
      }
      final bytes = snapshot.data;
      if (bytes == null) {
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          bytes,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    },
  );
}
