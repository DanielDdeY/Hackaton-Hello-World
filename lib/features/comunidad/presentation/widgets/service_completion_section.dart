import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../create_post/domain/services/auth_gateway.dart';
import '../../../economy/domain/models/economy_result.dart';
import '../../../economy/domain/services/economy_engine.dart';
import '../../../economy/presentation/economy_failure_messages.dart';
import '../../../notifications/domain/publication_activity.dart';
import '../../domain/entities/comunidad_feed_items.dart';
import '../tabs/feed_widgets.dart';

class ServiceCompletionSection extends StatefulWidget {
  const ServiceCompletionSection({super.key, required this.item});

  final ServiceItem item;

  @override
  State<ServiceCompletionSection> createState() =>
      _ServiceCompletionSectionState();
}

class _ServiceCompletionSectionState extends State<ServiceCompletionSection> {
  late final _repository = context.read<PublicationActivityRepository?>();
  late final _uid = context.read<AuthGateway?>()?.currentUid;
  bool get _asProvider => _uid != null && widget.item.authorId == _uid;
  late Stream<List<ServiceRequest>>? _requests = _watchRequests();
  bool _saving = false;

  Stream<List<ServiceRequest>>? _watchRequests() => _uid == null
      ? null
      : _repository?.watchServiceRequests(
          widget.item.id,
          asProvider: _asProvider,
        );

  Future<void> _markDelivered(ServiceRequest request) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _repository!.markServiceDelivered(
        postId: widget.item.id,
        requesterUid: request.requesterUid,
      );
      _showMessage(
        'Trabajo marcado como realizado. Falta que el cliente confirme.',
      );
    } on PublicationActivityFailure {
      _showMessage('La solicitud ya no está disponible.');
    } on Exception {
      _showMessage('No se pudo marcar el trabajo. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmReceived(
    String operationId,
    EconomyEngine engine,
  ) async {
    if (_saving) return;
    final rating = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Confirma y califica el servicio'),
        children: [
          for (var stars = 1; stars <= 5; stars++)
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(stars == 1 ? '1 estrella' : '$stars estrellas'),
              onTap: () => Navigator.pop(dialogContext, stars),
            ),
        ],
      ),
    );
    if (!mounted || rating == null || _saving) return;
    setState(() => _saving = true);
    try {
      final result = await engine.confirmService(
        postId: widget.item.id,
        rating: rating,
        operationId: operationId,
      );
      _showMessage(
        result.alreadyApplied
            ? 'La recepción ya estaba confirmada.'
            : 'Servicio confirmado. Recibiste ${result.clientXp} XP y ${result.coins} monedas.',
      );
    } on EconomyFailure catch (error) {
      _showMessage(economyFailureMessage(error));
    } on Exception {
      _showMessage('No se pudo confirmar la recepción. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_requests == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Divider(height: 1),
        Text(
          _asProvider ? 'Solicitudes recibidas' : 'Estado de tu solicitud',
          style: theme.textTheme.titleMedium,
        ),
        StreamBuilder<List<ServiceRequest>>(
          stream: _requests,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return FeedMessage(
                'No se pudieron cargar las solicitudes.',
                onRetry: () => setState(() => _requests = _watchRequests()),
              );
            }
            if (!snapshot.hasData) {
              return const LinearProgressIndicator(
                semanticsLabel: 'Cargando solicitudes',
              );
            }
            final requests = snapshot.data!;
            return _asProvider
                ? _buildProviderRequests(requests)
                : _buildCustomerRequest(context, requests.firstOrNull);
          },
        ),
      ],
    );
  }

  Widget _buildProviderRequests(List<ServiceRequest> requests) {
    if (requests.isEmpty) return const Text('Aún no hay solicitudes.');
    return Column(
      children: [
        for (final request in requests)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(request.requesterName),
            subtitle: Text(
              request.isCompleted
                  ? 'Recepción confirmada'
                  : request.completionOperationId != null
                  ? 'Esperando confirmación del cliente'
                  : 'Solicitud pendiente',
            ),
            trailing:
                request.completionOperationId == null && !request.isCompleted
                ? TextButton(
                    onPressed: _saving ? null : () => _markDelivered(request),
                    child: const Text('Trabajo realizado'),
                  )
                : null,
          ),
      ],
    );
  }

  Widget _buildCustomerRequest(BuildContext context, ServiceRequest? request) {
    if (request == null) return const Text('Envía una solicitud para empezar.');
    if (request.isCompleted) return const Text('Recepción confirmada');
    final operationId = request.completionOperationId;
    if (operationId == null) {
      return const Text(
        'Esperando que el proveedor marque el trabajo como realizado.',
      );
    }
    final engine = context.read<EconomyEngine?>();
    return FilledButton(
      onPressed: _saving || engine == null
          ? null
          : () => _confirmReceived(operationId, engine),
      child: Text(_saving ? 'Confirmando…' : 'Confirmar recepción'),
    );
  }
}
