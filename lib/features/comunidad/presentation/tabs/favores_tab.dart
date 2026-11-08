import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/entities/comunidad_feed_items.dart';
import '../../domain/repositories/comunidad_feed_repository.dart';
import 'feed_widgets.dart';

class FavoresTab extends StatefulWidget {
  const FavoresTab({
    super.key,
    required this.repository,
    this.currentUserId,
  });

  final ComunidadFeedRepository repository;
  final String? currentUserId;

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

  String? get _resolvedUserId {
    if (widget.currentUserId != null) return widget.currentUserId;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
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
          itemBuilder: (context, index) => _HelpCard(
            item: items[index],
            repository: widget.repository,
            currentUserId: _resolvedUserId,
          ),
        );
      },
    );
  }
}

class _HelpCard extends StatefulWidget {
  const _HelpCard({
    required this.item,
    required this.repository,
    this.currentUserId,
  });

  final HelpItem item;
  final ComunidadFeedRepository repository;
  final String? currentUserId;

  @override
  State<_HelpCard> createState() => _HelpCardState();
}

class _HelpCardState extends State<_HelpCard> {
  bool _isLoading = false;

  Future<void> _handleAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

    final uid = widget.currentUserId;
    final isAuthor = uid != null && uid == item.authorId;
    final isHelper = uid != null && item.ayudantes.contains(uid);

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
                _PointsBadge(fichas: item.fichas, xp: item.xp),
                const ExcludeSemantics(child: Icon(Icons.more_vert, size: 20)),
              ],
            ),
            Text(item.description, style: theme.textTheme.bodyMedium),
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
            const Divider(height: 1),
            // Acciones según estado y rol del usuario
            _buildActions(context, isAuthor: isAuthor, isHelper: isHelper),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context, {
    required bool isAuthor,
    required bool isHelper,
  }) {
    final item = widget.item;
    final theme = Theme.of(context);

    if (item.estado == 'completado') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            Text(
              'Favor completado',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (isAuthor) {
      if (item.estado == 'esperandoConfirmacion') {
        return FilledButton.icon(
          onPressed: _isLoading
              ? null
              : () => _handleAction(
                    () => widget.repository.confirmarFavor(item.id),
                    '¡Favor confirmado y agradecido!',
                  ),
          icon: const Icon(Icons.verified, size: 18),
          label: Text(_isLoading ? 'Confirmando…' : 'Confirmar y agradecer'),
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Tu pedido de ayuda (${item.cuposTomados}/${item.cuposTotales} ayudantes)',
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    if (isHelper) {
      return Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            avatar: const Icon(Icons.volunteer_activism, size: 16),
            label: const Text('Estás ayudando'),
            backgroundColor:
                theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          ),
          if (item.estado == 'esperandoConfirmacion')
            const Text(
              'Esperando confirmación',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            )
          else
            OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _handleAction(
                        () => widget.repository.marcarFavorTerminado(item.id),
                        'Marcado como terminado. Esperando al autor.',
                      ),
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(_isLoading ? 'Guardando…' : 'Marcar como terminado'),
            ),
        ],
      );
    }

    // Usuario vecino (no autor, no ayudante todavía)
    if (item.tieneCupo) {
      return FilledButton.tonalIcon(
        onPressed: _isLoading
            ? null
            : () => _handleAction(
                  () => widget.repository.postularAFavor(item.id),
                  '¡Te has postulado para ayudar!',
                ),
        icon: const Icon(Icons.handshake_outlined, size: 18),
        label: Text(_isLoading ? 'Quiero ayudar' : 'Quiero ayudar'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Cupos completos', style: TextStyle(fontSize: 12)),
    );
  }

  static String _titleFromDescription(String description) {
    final firstLine = description.split('\n').first.trim().characters;
    return firstLine.length <= 54
        ? firstLine.toString()
        : '${firstLine.take(54)}…';
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.fichas, required this.xp});

  final int fichas;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB703), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          SvgPicture.asset(
            'assets/ficha.svg',
            width: 14,
            height: 14,
          ),
          Flexible(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: Color(0xFF7A4A00)),
                children: [
                  TextSpan(
                    text: '+$fichas',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' ($xp XP)',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
