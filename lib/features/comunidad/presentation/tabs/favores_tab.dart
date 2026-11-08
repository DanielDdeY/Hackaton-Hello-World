import 'package:flutter/material.dart';

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
          itemBuilder: (context, index) => _HelpCard(item: items[index]),
        );
      },
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.item});

  final HelpItem item;

  @override
  Widget build(BuildContext context) {
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
                const _PointsBadge(),
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

class _PointsBadge extends StatelessWidget {
  const _PointsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 122),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB703), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(Icons.stars_rounded, size: 16, color: Color(0xFFD48B00)),
          Flexible(
            child: Text.rich(
              TextSpan(
                style: TextStyle(color: Color(0xFF7A4A00)),
                children: [
                  TextSpan(
                    text: '+5 pts',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' (10 XP)', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
