import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../data/active_sos_alerts.dart';
import '../domain/emergency_type_labels.dart';

/// Aviso compacto para Inicio: solo aparece cuando hay alertas SOS activas.
class SosAlertBanner extends StatelessWidget {
  const SosAlertBanner({super.key, this.alerts, this.onOpenMap});

  final Stream<List<Map<String, dynamic>>>? alerts;
  final void Function(LatLng? location)? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final alertsStream = alerts ?? ActiveSosAlerts().watch();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: alertsStream,
      builder: (context, snapshot) {
        final active = snapshot.data;
        if (active == null || active.isEmpty) {
          return const SizedBox.shrink();
        }
        final sorted = sortSosAlerts(active);
        return _Banner(alerts: sorted, onOpenMap: onOpenMap);
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.alerts, this.onOpenMap});

  final List<Map<String, dynamic>> alerts;
  final void Function(LatLng? location)? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final latest = alerts.first;
    final type = emergencyTypeLabel(latest['emergencyType'] as String?);
    final title = latest['title'] as String? ?? 'Alerta SOS cercana';
    final time = sosRelativeTime(latest['createdAt']);
    final count = alerts.length;

    return Material(
      color: const Color(0xfffff1f0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffc62828), width: 1.5),
      ),
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Color(0xffb71c1c)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            count == 1
                                ? 'SOS · $type'
                                : '$count alertas SOS · $type',
                            style: const TextStyle(
                              color: Color(0xffb71c1c),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xff5c5c5c),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => _openDetails(context),
                child: const Text('Ver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Alertas SOS cercanas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _AlertDetails(alert: alerts[index]),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  final location = sosAlertLocation(alerts.first);
                  Navigator.of(sheetContext).pop();
                  if (onOpenMap != null) {
                    onOpenMap!(location);
                  } else {
                    Navigator.of(context).pushNamed('/map');
                  }
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver en el mapa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertDetails extends StatelessWidget {
  const _AlertDetails({required this.alert});

  final Map<String, dynamic> alert;

  @override
  Widget build(BuildContext context) {
    final type = emergencyTypeLabel(alert['emergencyType'] as String?);
    final title = alert['title'] as String? ?? 'Alerta SOS cercana';
    final description = alert['description'] as String? ?? '';
    final time = sosRelativeTime(alert['createdAt']);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfffff1f0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffc62828)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SOS · $type',
                  style: const TextStyle(
                    color: Color(0xffb71c1c),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: Color(0xff5c5c5c)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(description),
          ],
        ],
      ),
    );
  }
}
