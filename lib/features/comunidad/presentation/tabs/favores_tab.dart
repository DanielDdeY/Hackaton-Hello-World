import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../economy/domain/models/economy_result.dart';
import '../../../economy/domain/services/economy_engine.dart';
import '../../../economy/presentation/economy_failure_messages.dart';
import '../../domain/entities/comunidad_feed_items.dart';
import '../../domain/repositories/comunidad_feed_repository.dart';
import 'feed_widgets.dart';

class FavoresTab extends StatefulWidget {
  const FavoresTab({super.key, required this.repository});

  final ComunidadFeedRepository repository;

  @override
  State<FavoresTab> createState() => _FavoresTabState();
}

class _FavoresTabState extends State<FavoresTab>
    with AutomaticKeepAliveClientMixin<FavoresTab> {
  late Stream<List<HelpItem>> _favors = widget.repository.watchFavors();

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant FavoresTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) {
      _favors = widget.repository.watchFavors();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<HelpItem>>(
      stream: _favors,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Cargando favores',
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: FeedMessage(
              'No se pudieron cargar los favores.',
              onRetry: () =>
                  setState(() => _favors = widget.repository.watchFavors()),
            ),
          );
        }
        final items = snapshot.data ?? const <HelpItem>[];
        if (items.isEmpty) {
          return const Center(
            child: FeedMessage('Aún no hay favores publicados.'),
          );
        }
        return ListView.separated(
          key: const PageStorageKey('comunidad-favores'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return _HelpCard(
              key: ValueKey(item.id),
              item: item,
              repository: widget.repository,
            );
          },
        );
      },
    );
  }
}

class _HelpCard extends StatefulWidget {
  const _HelpCard({super.key, required this.item, required this.repository});

  final HelpItem item;
  final ComunidadFeedRepository repository;

  @override
  State<_HelpCard> createState() => _HelpCardState();
}

class _HelpCardState extends State<_HelpCard> {
  late Stream<HelpParticipation> _participation = widget.repository
      .watchHelpParticipation(widget.item);
  bool _saving = false;

  @override
  void didUpdateWidget(covariant _HelpCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.item.authorId != widget.item.authorId) {
      _participation = widget.repository.watchHelpParticipation(widget.item);
    }
  }

  Future<void> _offerHelp() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.repository.offerHelp(widget.item.id);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar tu ayuda.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmHelp(HelpOffer offer, EconomyEngine engine) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await engine.confirmFavor(postId: widget.item.id, helperUid: offer.uid);
    } on EconomyFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(economyFailureMessage(error))));
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo confirmar la ayuda.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildParticipation() {
    return StreamBuilder<HelpParticipation>(
      stream: _participation,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextButton(
            onPressed: () => setState(() {
              _participation = widget.repository.watchHelpParticipation(
                widget.item,
              );
            }),
            child: const Text('Reintentar consulta de ayuda'),
          );
        }
        final participation = snapshot.data;
        if (participation?.offers case final offers?) {
          if (offers.isEmpty) return const Text('Nadie ha ofrecido ayuda aún');
          final engine = context.read<EconomyEngine?>();
          return ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              offers.length == 1
                  ? '1 persona ofreció ayuda'
                  : '${offers.length} personas ofrecieron ayuda',
            ),
            children: [
              for (final offer in offers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(offer.name),
                  subtitle: offer.isConfirmed
                      ? const Text('Ayuda confirmada')
                      : null,
                  trailing: offer.isConfirmed
                      ? const Icon(Icons.check)
                      : TextButton(
                          onPressed: _saving || engine == null
                              ? null
                              : () => _confirmHelp(offer, engine),
                          child: const Text('Confirmar ayuda'),
                        ),
                ),
            ],
          );
        }
        final offered = participation?.hasOffered ?? false;
        return FilledButton.tonalIcon(
          onPressed: participation == null || offered || _saving
              ? null
              : _offerHelp,
          icon: Icon(offered ? Icons.check : Icons.volunteer_activism_outlined),
          label: Text(
            _saving
                ? 'Guardando…'
                : participation?.isConfirmed == true
                ? 'Ayuda confirmada · +${EconomyResult.favorXp} XP'
                : offered
                ? 'Ayuda ofrecida'
                : 'Ayudar',
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final location = item.location ?? 'N/A';
    final people = item.peopleNeeded;
    final peopleColor = people == null
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        item.title ?? _titleFromDescription(item.description),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        item.authorName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                RewardBadge(
                  label: item.hasReward ? 'Con recompensa' : 'Sin recompensa',
                  highlighted: item.hasReward,
                ),
                const ExcludeSemantics(child: Icon(Icons.more_vert, size: 20)),
              ],
            ),
            Text(item.description, style: theme.textTheme.bodyMedium),
            const RewardBadge(
              label: '+${EconomyResult.favorXp} XP',
              detail: 'Al confirmar la ayuda',
            ),
            if (item.hasReward && item.rewardDescription != null)
              Text(
                'Recompensa: ${item.rewardDescription}',
                style: theme.textTheme.bodySmall,
              ),
            Row(
              spacing: 6,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                Expanded(
                  child: Semantics(
                    label: 'Ubicación: $location',
                    excludeSemantics: true,
                    child: Text(
                      location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: peopleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: peopleColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Personas: ${people ?? 'N/A'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: peopleColor,
                    ),
                  ),
                ),
              ],
            ),
            _buildParticipation(),
          ],
        ),
      ),
    );
  }

  static String _titleFromDescription(String description) {
    final firstLine = description.split('\n').first.trim().characters;
    return firstLine.length <= 54
        ? firstLine.toString()
        : '${firstLine.take(54)}…';
  }
}
