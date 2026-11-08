import 'package:flutter/material.dart';

import '../domain/publication_activity.dart';

Future<void> showPublicationNotifications(
  BuildContext context,
  PublicationActivityRepository? repository,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) => _PublicationNotificationsSheet(repository: repository),
);

class _PublicationNotificationsSheet extends StatefulWidget {
  const _PublicationNotificationsSheet({required this.repository});

  final PublicationActivityRepository? repository;

  @override
  State<_PublicationNotificationsSheet> createState() =>
      _PublicationNotificationsSheetState();
}

class _PublicationNotificationsSheetState
    extends State<_PublicationNotificationsSheet> {
  late Stream<List<PublicationActivity>>? _stream = widget.repository
      ?.watchReceived();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Notificaciones',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<PublicationActivity>>(
                  stream: _stream,
                  builder: _buildActivity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivity(
    BuildContext context,
    AsyncSnapshot<List<PublicationActivity>> snapshot,
  ) {
    if (_stream == null ||
        snapshot.error == PublicationActivityFailure.noSession) {
      return const Center(child: Text('Inicia sesión para ver tus avisos.'));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Cargando notificaciones',
        ),
      );
    }
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudieron cargar tus notificaciones.'),
            TextButton(
              onPressed: () =>
                  setState(() => _stream = widget.repository?.watchReceived()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    final items = snapshot.data ?? const <PublicationActivity>[];
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Aún no hay actividad en tus publicaciones.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _ActivityTile(item: items[index]),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final PublicationActivity item;

  @override
  Widget build(BuildContext context) {
    final (icon, action) = switch (item.kind) {
      PublicationActivityKind.helpOffer => (
        Icons.volunteer_activism_outlined,
        'se ofreció a ayudarte',
      ),
      PublicationActivityKind.eventAttendance => (
        Icons.event_available_outlined,
        'confirmó asistencia',
      ),
      PublicationActivityKind.serviceRequest => (
        Icons.handshake_outlined,
        'solicitó tu servicio',
      ),
    };
    final timestamp = item.occurredAt?.toLocal();
    final labels = MaterialLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text('${item.actorName} $action'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.postTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (timestamp != null)
            Text(
              '${labels.formatShortDate(timestamp)} · '
              '${labels.formatTimeOfDay(TimeOfDay.fromDateTime(timestamp))}',
            ),
        ],
      ),
    );
  }
}
