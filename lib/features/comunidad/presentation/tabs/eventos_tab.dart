import 'package:flutter/material.dart';

import '../../../create_post/domain/entities/news_post_data.dart';
import '../../domain/entities/comunidad_feed_items.dart';
import '../../domain/repositories/comunidad_feed_repository.dart';
import 'feed_widgets.dart';

class EventosTab extends StatefulWidget {
  const EventosTab({super.key, required this.repository});

  final ComunidadFeedRepository repository;

  @override
  State<EventosTab> createState() => _EventosTabState();
}

class _EventosTabState extends State<EventosTab>
    with AutomaticKeepAliveClientMixin<EventosTab> {
  late Stream<List<EventItem>> _events = widget.repository.watchEvents();
  late Stream<List<NewsItem>> _news = widget.repository.watchNews();

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant EventosTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) {
      _events = widget.repository.watchEvents();
      _news = widget.repository.watchNews();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      key: const PageStorageKey('comunidad-eventos'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverMainAxisGroup(
            slivers: [
              const SliverToBoxAdapter(
                child: _SectionTitle('Próximos eventos'),
              ),
              _FeedSection<EventItem>(
                stream: _events,
                emptyMessage: 'Aún no hay eventos programados',
                errorMessage: 'No se pudieron cargar los eventos.',
                onRetry: () =>
                    setState(() => _events = widget.repository.watchEvents()),
                itemBuilder: (context, item) => _EventCard(event: item),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: _SectionTitle('Noticias del barrio'),
                ),
              ),
              _FeedSection<NewsItem>(
                stream: _news,
                emptyMessage: 'Aún no hay noticias del barrio.',
                errorMessage: 'No se pudieron cargar las noticias.',
                onRetry: () =>
                    setState(() => _news = widget.repository.watchNews()),
                itemBuilder: (context, item) => _NewsCard(news: item),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedSection<T> extends StatelessWidget {
  const _FeedSection({
    required this.stream,
    required this.emptyMessage,
    required this.errorMessage,
    required this.onRetry,
    required this.itemBuilder,
  });

  final Stream<List<T>> stream;
  final String emptyMessage;
  final String errorMessage;
  final VoidCallback onRetry;
  final Widget Function(BuildContext, T) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(semanticsLabel: 'Cargando'),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: FeedMessage(errorMessage, onRetry: onRetry),
          );
        }
        final items = snapshot.data;
        if (items == null || items.isEmpty) {
          return SliverToBoxAdapter(child: FeedMessage(emptyMessage));
        }
        return SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(context, items[index]),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final EventItem event;

  static const _months = [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labels = MaterialLocalizations.of(context);
    final date = event.startsAt.toLocal();
    final time = labels.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: true,
    );
    final description = event.description;
    final attendees = event.attendees;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Semantics(
                  label: labels.formatFullDate(date),
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.25),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          date.day.toString().padLeft(2, '0'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                        Text(
                          _months[date.month - 1],
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'Evento vecinal',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                      Text(event.title, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
            if (description != null) Text(description),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _EventMetadata(icon: Icons.schedule, text: time),
                _EventMetadata(icon: Icons.place_outlined, text: event.place),
              ],
            ),
            if (attendees != null) ...[
              const Divider(height: 1),
              _EventMetadata(
                icon: Icons.people_outline,
                text: attendees == 1
                    ? '1 asistente previsto'
                    : '$attendees asistentes previstos',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventMetadata extends StatelessWidget {
  const _EventMetadata({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(icon, size: 16, color: color),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news});

  final NewsItem news;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topic = _topicLabel(news.quickCategory);
    final date = news.createdAt;
    final photo = news.photoUrls.firstOrNull;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showFeedDetail(
          context,
          (context) => [
            Text(news.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              date == null
                  ? news.authorName
                  : '${news.authorName} · ${_relativeTime(date)}',
            ),
            if (topic != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(label: Text(topic)),
              ),
            const SizedBox(height: 16),
            Text(news.content),
            if (news.isUploading || news.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              FeedPhotos(urls: news.photoUrls, isUploading: news.isUploading),
            ],
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(news.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      news.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (date != null || topic != null)
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (topic != null)
                            Chip(
                              label: Text(topic),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (date != null)
                            Text(
                              _relativeTime(date),
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              if (photo != null) ...[
                const SizedBox(width: 12),
                SizedBox.square(
                  dimension: 72,
                  child: FeedPhoto(
                    url: photo,
                    label: 'Miniatura de la noticia',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String? _topicLabel(NewsTopic? topic) => switch (topic) {
  NewsTopic.generalNotice => 'Aviso general',
  NewsTopic.lostPet => 'Mascota perdida',
  NewsTopic.neighborhoodLife => 'Vida vecinal',
  NewsTopic.worksOrOutages => 'Obras o cortes de servicio',
  null => null,
};

String _relativeTime(DateTime date) {
  final elapsed = DateTime.now().difference(date);
  if (elapsed.inDays > 0) return 'hace ${elapsed.inDays} d';
  if (elapsed.inHours > 0) return 'hace ${elapsed.inHours} h';
  if (elapsed.inMinutes > 0) return 'hace ${elapsed.inMinutes} min';
  return 'Ahora';
}
