import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../emergency/data/active_sos_alerts.dart';
import '../../emergency/domain/emergency_type_labels.dart';

class CommunitySosSection extends StatelessWidget {
  const CommunitySosSection({super.key, this.alerts, this.onOpenMap});

  final Stream<List<Map<String, dynamic>>>? alerts;
  final void Function(LatLng? location)? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final alertsStream = alerts ?? ActiveSosAlerts().watch();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: alertsStream,
      builder: (context, snapshot) {
        final sorted = snapshot.hasData
            ? sortSosAlerts(snapshot.data!)
            : const <Map<String, dynamic>>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SosHeader(count: sorted.length),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _body(context, snapshot, sorted),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    List<Map<String, dynamic>> sorted,
  ) {
    if (snapshot.hasError) {
      return const _CompactMessage(
        key: ValueKey('sos-error'),
        icon: Icons.cloud_off_outlined,
        message: 'No se pudieron cargar las alertas SOS.',
      );
    }
    if (!snapshot.hasData) {
      return const Padding(
        key: ValueKey('sos-loading'),
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (sorted.isEmpty) {
      return const _CompactMessage(
        key: ValueKey('sos-empty'),
        icon: Icons.notifications_none_outlined,
        message: 'No hay alertas SOS activas en este momento.',
      );
    }
    return Column(
      key: ValueKey('sos-list-${sorted.length}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < sorted.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          _SosAlertCard(
            alert: sorted[index],
            initiallyExpanded: index == 0,
            onOpenMap: onOpenMap,
          ),
        ],
      ],
    );
  }
}

class _SosHeader extends StatelessWidget {
  const _SosHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const _PulsingDot(),
      const SizedBox(width: 8),
      const Text(
        'Alertas SOS cercanas',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const Spacer(),
      if (count > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xffb71c1c),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count activa${count == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
    ],
  );
}

class _CompactMessage extends StatelessWidget {
  const _CompactMessage({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xff5c5c5c)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Color(0xff5c5c5c)),
        ),
      ),
    ],
  );
}

class _PulsingDot extends StatelessWidget {
  const _PulsingDot();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 16,
    height: 16,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: .55, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, pulse, child) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 16 * pulse,
            height: 16 * pulse,
            decoration: BoxDecoration(
              color: const Color(0xffb71c1c).withValues(alpha: .18 * pulse),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xffb71c1c),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SosAlertCard extends StatefulWidget {
  const _SosAlertCard({
    required this.alert,
    this.initiallyExpanded = true,
    this.onOpenMap,
  });

  final Map<String, dynamic> alert;
  final bool initiallyExpanded;
  final void Function(LatLng? location)? onOpenMap;

  @override
  State<_SosAlertCard> createState() => _SosAlertCardState();
}

class _SosAlertCardState extends State<_SosAlertCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final type = emergencyTypeLabel(alert['emergencyType'] as String?);
    final title = alert['title'] as String? ?? 'Alerta SOS cercana';
    final description = alert['description'] as String? ?? '';
    final photoPath = alert['photoPath'] as String?;
    final detailsPending = alert['detailsPending'] == true;
    final relativeTime = sosRelativeTime(alert['createdAt']);
    final hasDetails =
        description.isNotEmpty || photoPath != null || detailsPending;

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
            InkWell(
              onTap: hasDetails
                  ? () => setState(() => _expanded = !_expanded)
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Row(
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
                  Text(
                    relativeTime,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff5c5c5c),
                    ),
                  ),
                  if (hasDetails)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xffb71c1c),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (_expanded) ...[
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    final location = sosAlertLocation(alert);
                    if (widget.onOpenMap != null) {
                      widget.onOpenMap!(location);
                    } else {
                      Navigator.of(context).pushNamed('/map');
                    }
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Ver en mapa'),
                ),
              ),
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
