import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../create_post/domain/entities/service_availability.dart';
import '../../../create_post/domain/entities/service_category.dart';
import '../../../create_post/domain/entities/service_post_data.dart';
import '../../../create_post/domain/services/auth_gateway.dart';
import '../../../economy/domain/models/economy_result.dart';
import '../../../economy/domain/services/economy_engine.dart';
import '../../../economy/domain/services/period_provider.dart';
import '../../../economy/presentation/economy_failure_messages.dart';
import '../../../notifications/domain/publication_activity.dart';
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(item.title, style: theme.textTheme.titleMedium),
                  ),
                  const Tooltip(
                    message: 'Recompensa por dar Visto Bueno al servicio',
                    child: RewardBadge(
                      label: '+${EconomyResult.serviceClientXp} XP cliente',
                      detail: '+${EconomyResult.serviceProviderXp} XP proveedor',
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ServiceAction(item: item),
          ],
        ),
        _ServiceVistoBuenoSection(item: item),
      ],
    );
  }
}

class _ServiceVistoBuenoSection extends StatefulWidget {
  const _ServiceVistoBuenoSection({required this.item});

  final ServiceItem item;

  @override
  State<_ServiceVistoBuenoSection> createState() =>
      _ServiceVistoBuenoSectionState();
}

class _ServiceVistoBuenoSectionState extends State<_ServiceVistoBuenoSection> {
  bool _selectingRating = false;
  bool _submitting = false;
  int _rating = 5;
  int _confirmedSlots = 0;
  bool _isOwnService = false;
  String? _statusMessage;
  String? _pendingOperationId;
  int? _pendingRating;

  String _slotsKey(String uid, String period) =>
      'vb_slots_${period}_${uid}_${widget.item.id}';
  String _ownKey(String uid) => 'vb_own_${uid}_${widget.item.id}';
  String _pendingOpKey(String uid, String period, int nextSlot) =>
      'vb_op_${period}_${uid}_${widget.item.id}_$nextSlot';
  String _pendingRatingKey(String uid, String period, int nextSlot) =>
      'vb_rating_${period}_${uid}_${widget.item.id}_$nextSlot';

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    final auth = context.read<AuthGateway?>();
    final periods = context.read<PeriodProvider?>();
    final uid = auth?.currentUid;
    final period = periods?.currentPeriod ?? '';
    if (uid == null || uid.isEmpty || period.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final own = prefs.getBool(_ownKey(uid)) ?? false;
      final slots = prefs.getInt(_slotsKey(uid, period)) ?? 0;
      final nextSlot = (slots + 1).clamp(1, 2);
      final savedOp = prefs.getString(_pendingOpKey(uid, period, nextSlot));
      final savedRating = prefs.getInt(
        _pendingRatingKey(uid, period, nextSlot),
      );
      if (!mounted) return;
      setState(() {
        _isOwnService = own;
        _confirmedSlots = slots;
        _pendingOperationId = savedOp;
        if (savedRating != null && savedRating >= 1 && savedRating <= 5) {
          _rating = savedRating;
          _pendingRating = savedRating;
        }
      });
    } catch (_) {
      // Continúa con el estado en memoria si SharedPreferences no responde.
    }
  }

  Future<void> _confirmVistoBueno() async {
    if (_submitting) return;
    final engine = context.read<EconomyEngine?>();
    final auth = context.read<AuthGateway?>();
    final periods = context.read<PeriodProvider?>();
    if (engine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El motor de economía no está disponible.'),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _statusMessage = null;
    });

    final uid = auth?.currentUid ?? '';
    final period = periods?.currentPeriod ?? '';
    final nextSlot = (_confirmedSlots + 1).clamp(1, 2);

    try {
      // Si había un intento previo sin confirmar (ej. caída de red), se reutiliza
      // el mismo operationId y rating para que nunca cuente como un segundo uso.
      final ratingToUse = _pendingOperationId != null && _pendingRating != null
          ? _pendingRating!
          : _rating;
      final operationId = _pendingOperationId ?? engine.newOperationId();
      _pendingOperationId = operationId;
      _pendingRating = ratingToUse;

      if (uid.isNotEmpty && period.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _pendingOpKey(uid, period, nextSlot),
          operationId,
        );
        await prefs.setInt(
          _pendingRatingKey(uid, period, nextSlot),
          ratingToUse,
        );
      }

      final result = await engine.confirmService(
        postId: widget.item.id,
        rating: ratingToUse,
        operationId: operationId,
      );

      if (uid.isNotEmpty && period.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_pendingOpKey(uid, period, nextSlot));
        await prefs.remove(_pendingRatingKey(uid, period, nextSlot));
        await prefs.setInt(_slotsKey(uid, period), result.slot);
      }

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _selectingRating = false;
        _confirmedSlots = result.slot;
        _pendingOperationId = null;
        _pendingRating = null;
        _statusMessage = result.slot >= 2
            ? 'Completaste tus 2 Vistos Buenos del mes para este servicio.'
            : 'Visto Bueno registrado (${result.slot}/2 usos este mes).';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyApplied
                ? 'Tu confirmación ya había sido registrada (+${result.clientXp} XP).'
                : '+${result.clientXp} XP por dar tu Visto Bueno (${result.slot}/2 este mes).',
          ),
        ),
      );
    } on EconomyFailure catch (failure) {
      final msg = economyFailureMessage(failure);
      if (uid.isNotEmpty && period.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        if (failure.reason == EconomyFailureReason.selfConfirmation) {
          await prefs.setBool(_ownKey(uid), true);
        } else if (failure.reason ==
            EconomyFailureReason.monthlyPairLimitReached) {
          await prefs.setInt(_slotsKey(uid, period), 2);
        }
        // Si el error no es de red, liberamos el operationId pendiente.
        if (failure.reason != EconomyFailureReason.networkUnavailable &&
            failure.reason != EconomyFailureReason.unavailable) {
          await prefs.remove(_pendingOpKey(uid, period, nextSlot));
          await prefs.remove(_pendingRatingKey(uid, period, nextSlot));
          _pendingOperationId = null;
          _pendingRating = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _submitting = false;
        if (failure.reason == EconomyFailureReason.selfConfirmation) {
          _isOwnService = true;
          _selectingRating = false;
        } else if (failure.reason ==
            EconomyFailureReason.monthlyPairLimitReached) {
          _confirmedSlots = 2;
          _selectingRating = false;
        }
        _statusMessage = msg;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      const msg =
          'No se pudo confirmar. Reintenta con la misma solicitud.';
      setState(() {
        _submitting = false;
        _statusMessage = msg;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final limitReached = _confirmedSlots >= 2;
    final disabled = _isOwnService || limitReached;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Divider(height: 1),
        if (!_selectingRating)
          FilledButton.icon(
            onPressed: disabled || _submitting
                ? null
                : () => setState(() => _selectingRating = true),
            icon: const Icon(Icons.verified_outlined),
            label: Text(
              _confirmedSlots == 1
                  ? 'Dar Visto Bueno (2° uso del mes)'
                  : 'Dar Visto Bueno',
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  _pendingOperationId != null
                      ? 'Reintentar confirmación pendiente (${_pendingRating ?? _rating} ★)'
                      : 'Califica el servicio (1 a 5 estrellas)',
                  style: theme.textTheme.titleSmall,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var star = 1; star <= 5; star++)
                      IconButton(
                        tooltip: '$star estrellas',
                        onPressed: _submitting || _pendingOperationId != null
                            ? null
                            : () => setState(() => _rating = star),
                        icon: Icon(
                          star <= (_pendingRating ?? _rating)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: colors.secondary,
                          size: 28,
                        ),
                      ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _submitting ? null : _confirmVistoBueno,
                      icon: _submitting
                          ? SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                          : const Icon(Icons.check),
                      label: Text(
                        _submitting
                            ? 'Confirmando...'
                            : _pendingOperationId != null
                            ? 'Reintentar confirmación'
                            : 'Confirmar (+${EconomyResult.serviceClientXp} XP)',
                      ),
                    ),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _selectingRating = false),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (_isOwnService)
          Text(
            'No puedes dar Visto Bueno a tu propio servicio.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          )
        else if (limitReached)
          Text(
            'Ya recibiste XP por dos usos con este proveedor este mes.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          )
        else if (_statusMessage != null)
            Text(
              _statusMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
      ],
    );
  }
}

enum _ServiceContactAction { request, call }

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
    final canRequest = activity != null &&
        (item.authorId == null || item.authorId != uid);
    final phone = item.contactPhone?.trim() ?? '';
    final dialNumber = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final canCall = RegExp(r'^\+?[0-9]+$').hasMatch(dialNumber);
    final action = await showDialog<_ServiceContactAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label · ${item.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phone.isEmpty
                  ? 'Esta publicación no tiene un teléfono de contacto.'
                  : 'Coordina directamente con el anunciante usando este teléfono.',
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
          if (canCall)
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, _ServiceContactAction.call),
              icon: const Icon(Icons.phone_outlined),
              iconAlignment: IconAlignment.start,
              label: const Text('Llamar'),
            ),
          if (canRequest)
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, _ServiceContactAction.request),
              child: const Text('Enviar solicitud'),
            ),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == _ServiceContactAction.request) {
      if (activity != null) await _sendRequest(activity);
      return;
    }
    var opened = false;
    try {
      opened = await launchUrl(
        Uri(scheme: 'tel', path: dialNumber),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // El usuario puede seleccionar el teléfono si no hay app de llamadas.
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el teléfono. Contacta al $phone.'),
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
        PublicationActivityFailure.noSession => 'Inicia sesión para enviar una solicitud.',
        PublicationActivityFailure.serviceUnavailable => 'La publicación ya no está disponible.',
        PublicationActivityFailure.ownService => 'Esta publicación es tuya.',
      };
    } on Exception {
      message = 'No se pudo enviar la solicitud. Inténtalo de nuevo.';
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
