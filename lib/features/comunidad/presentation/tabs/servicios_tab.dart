import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/validators/peruvian_phone_validator.dart';
import '../../../create_post/domain/entities/service_availability.dart';
import '../../../create_post/domain/entities/service_category.dart';
import '../../../create_post/domain/entities/service_post_data.dart';
import '../../../create_post/domain/services/auth_gateway.dart';
import '../../../economy/domain/models/economy_result.dart';
import '../../../notifications/domain/publication_activity.dart';
import '../../domain/entities/comunidad_feed_items.dart';
import '../../domain/repositories/comunidad_feed_repository.dart';
import '../widgets/service_completion_section.dart';
import 'feed_widgets.dart';

class ServiciosTab extends StatefulWidget {
  const ServiciosTab({super.key, required this.repository});

  final ComunidadFeedRepository repository;

  @override
  State<ServiciosTab> createState() => _ServiciosTabState();
}

class _ServiciosTabState extends State<ServiciosTab>
    with AutomaticKeepAliveClientMixin<ServiciosTab> {
  ServiceCategory? _category;
  late Stream<List<ServiceItem>> _services = widget.repository.watchServices();

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant ServiciosTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) {
      _services = widget.repository.watchServices(category: _category);
    }
  }

  void _selectCategory(ServiceCategory? category) {
    if (_category == category) return;
    setState(() {
      _category = category;
      _services = widget.repository.watchServices(category: category);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        SingleChildScrollView(
          key: const PageStorageKey('comunidad-categorias'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            spacing: 8,
            children: [
              for (final category in [null, ...ServiceCategory.values])
                ChoiceChip(
                  label: Text(category?.label ?? 'Todos'),
                  selected: category == _category,
                  onSelected: (_) => _selectCategory(category),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ServiceItem>>(
            stream: _services,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Cargando servicios',
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: FeedMessage(
                    'No se pudieron cargar los servicios.',
                    onRetry: () => setState(() {
                      _services = widget.repository.watchServices(
                        category: _category,
                      );
                    }),
                  ),
                );
              }
              final items = snapshot.data;
              if (items == null || items.isEmpty) {
                return Center(
                  child: FeedMessage(
                    _category == null
                        ? 'Aún no hay servicios publicados.'
                        : 'No hay servicios en esta categoría.',
                  ),
                );
              }
              return ListView.separated(
                key: PageStorageKey(
                  'comunidad-servicios-${_category?.key ?? 'todos'}',
                ),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) =>
                    _ServiceCard(item: items[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item});

  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = context.read<AuthGateway?>()?.currentUid;
    final isOwner = uid != null && item.authorId == uid;
    void openDetails() =>
        showFeedDetail(context, (_) => [_ServiceDetail(item: item)]);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openDetails,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(item.title, style: theme.textTheme.titleMedium),
                  ),
                  const Tooltip(
                    message:
                        'Recompensa al confirmar la recepción del servicio',
                    child: RewardBadge(
                      label: '+${EconomyResult.serviceClientXp} XP cliente',
                      detail:
                          '+${EconomyResult.serviceProviderXp} XP proveedor · '
                          '${EconomyResult.serviceCoins} monedas c/u',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.information,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _priceLabel(item.price),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              if (isOwner)
                OutlinedButton(
                  onPressed: openDetails,
                  child: const Text('Ver solicitudes'),
                )
              else
                _ServiceAction(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceDetail extends StatelessWidget {
  const _ServiceDetail({required this.item});

  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payments = _paymentLabels(item);
    final mode = item.mode;
    final uid = context.read<AuthGateway?>()?.currentUid;
    final isOwner = uid != null && item.authorId == uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(item.title, style: theme.textTheme.headlineSmall),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(label: Text(item.category.label)),
            if (mode != null)
              Chip(
                label: Text(
                  mode == ServiceMode.sell ? 'Vender' : 'Brindar servicio',
                ),
              ),
          ],
        ),
        Text(item.information),
        Text(
          _priceLabel(item.price),
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        _DetailField(
          label: 'Medios de pago',
          child: Text(payments.isEmpty ? 'No indicados' : payments.join(' · ')),
        ),
        _DetailField(
          label: 'Celular',
          child: item.contactPhone == null
              ? const Text('No indicado')
              : SelectableText(item.contactPhone!),
        ),
        if (mode == ServiceMode.provideService)
          _DetailField(
            label: 'Disponibilidad',
            child: Text(_scheduleLabel(item.availability)),
          ),
        if (mode == ServiceMode.sell)
          _DetailField(
            label: 'Stock',
            child: Text(item.stock == null ? 'No indicado' : '${item.stock}'),
          ),
        if (item.isUploading || item.photoUrls.isNotEmpty)
          FeedPhotos(urls: item.photoUrls, isUploading: item.isUploading),
        if (!isOwner) _ServiceAction(item: item),
        ServiceCompletionSection(item: item),
      ],
    );
  }
}

class _ServiceAction extends StatefulWidget {
  const _ServiceAction({required this.item});

  final ServiceItem item;

  @override
  State<_ServiceAction> createState() => _ServiceActionState();
}

class _ServiceActionState extends State<_ServiceAction> {
  bool _requesting = false;
  ServiceItem get item => widget.item;

  String get label => switch (item.mode) {
    ServiceMode.sell => 'Pedir',
    ServiceMode.provideService => 'Contratar',
    null => 'Contactar',
  };

  Future<void> _contact(BuildContext context) async {
    final activity = context.read<PublicationActivityRepository?>();
    final uid = context.read<AuthGateway?>()?.currentUid;
    final canRequest =
        activity != null && (item.authorId == null || item.authorId != uid);
    final phone = item.contactPhone?.trim() ?? '';
    final canChat = PeruvianPhoneValidator.isValid(phone);
    final requested = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label · ${item.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              canChat
                  ? 'Coordina directamente con el anunciante por WhatsApp.'
                  : 'Esta publicación no tiene un celular válido para WhatsApp.',
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(phone),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (canChat)
            FilledButton.icon(
              onPressed: () => _openWhatsApp(phone),
              icon: const Icon(Icons.chat_outlined),
              iconAlignment: IconAlignment.start,
              label: const Text('WhatsApp'),
            ),
          if (canRequest)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar solicitud'),
            ),
        ],
      ),
    );
    if (requested == true && mounted && activity != null) {
      await _sendRequest(activity);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.https('wa.me', '/51$phone', {
          'text': 'Hola, vi «${item.title}» en AyniVeci y me interesa.',
        }),
        mode: LaunchMode.externalApplication,
      );
    } on Exception {
      // The selectable number is also available as a fallback.
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir WhatsApp. Celular: +51 $phone.'),
          action: SnackBarAction(
            label: 'Copiar',
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: '+51$phone')),
          ),
        ),
      );
    }
  }

  Future<void> _sendRequest(PublicationActivityRepository activity) async {
    if (_requesting) return;
    setState(() => _requesting = true);
    String message;
    try {
      final created = await activity.requestService(item.id);
      message = created
          ? 'Solicitud enviada al anunciante.'
          : 'Ya enviaste una solicitud para esta publicación.';
    } on PublicationActivityFailure catch (error) {
      message = switch (error) {
        PublicationActivityFailure.noSession =>
          'Inicia sesión para enviar una solicitud.',
        PublicationActivityFailure.serviceUnavailable =>
          'La publicación ya no está disponible.',
        PublicationActivityFailure.ownService => 'Esta publicación es tuya.',
        PublicationActivityFailure.requestUnavailable =>
          'La solicitud ya no está disponible.',
      };
    } on Exception {
      message = 'No se pudo enviar la solicitud. Inténtalo de nuevo.';
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _requesting ? null : () => _contact(context),
      icon: Icon(
        item.mode == ServiceMode.sell
            ? Icons.shopping_bag_outlined
            : Icons.handshake_outlined,
      ),
      label: Text(_requesting ? 'Enviando…' : label),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        child,
      ],
    );
  }
}

final _priceFormat = NumberFormat.currency(
  locale: 'es_PE',
  symbol: 'S/ ',
  decimalDigits: 2,
  customPattern: '¤#,##0.00',
);

String _priceLabel(num? price) {
  if (price == null) return 'Monto no indicado';
  // La tarjeta usa el separador decimal del diseño, por ejemplo S/ 25.00.
  final symbols = _priceFormat.symbols;
  final parts = _priceFormat.format(price).split(symbols.DECIMAL_SEP);
  return '${parts.first.replaceAll(symbols.GROUP_SEP, ',')}.${parts.last}';
}

const _payments = {
  'yape': 'Yape',
  'plin': 'Plin',
  'cash': 'Efectivo',
  'card': 'Tarjeta',
};

const _banks = {
  'bcp': 'BCP',
  'interbank': 'Interbank',
  'bbva': 'BBVA',
  'scotiabank': 'Scotiabank',
};

List<String> _paymentLabels(ServiceItem item) {
  final banks = [for (final bank in item.transferBanks) ?_banks[bank]];
  return [
    for (final method in item.paymentMethods)
      if (method == 'bank_transfer')
        banks.isEmpty
            ? 'Transferencia bancaria'
            : 'Transferencia (${banks.join(', ')})'
      else
        ?_payments[method],
  ];
}

const _days = {
  Weekday.monday: 'lunes',
  Weekday.tuesday: 'martes',
  Weekday.wednesday: 'miércoles',
  Weekday.thursday: 'jueves',
  Weekday.friday: 'viernes',
  Weekday.saturday: 'sábado',
  Weekday.sunday: 'domingo',
};

String _scheduleLabel(ServiceAvailability? availability) {
  if (availability == null || !availability.isValid) {
    return 'Sin horario indicado';
  }
  final days = [
    for (final day in Weekday.values)
      if (availability.days.contains(day)) _days[day]!,
  ].join(', ');
  return '$days\n${_timeLabel(availability.startMinute!)} – ${_timeLabel(availability.endMinute!)}';
}

String _timeLabel(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}
