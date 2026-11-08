import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../create_post/domain/entities/service_availability.dart';
import '../../../create_post/domain/entities/service_category.dart';
import '../../../create_post/domain/entities/service_post_data.dart';
import '../../domain/entities/comunidad_feed_items.dart';
import '../../domain/repositories/comunidad_feed_repository.dart';
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            showFeedDetail(context, (context) => [_ServiceDetail(item: item)]),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: theme.textTheme.titleMedium),
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
      ],
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
