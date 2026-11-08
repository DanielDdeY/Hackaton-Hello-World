import '../../../create_post/domain/entities/service_category.dart';
import '../../domain/entities/comunidad_feed_items.dart';
import '../../domain/repositories/comunidad_feed_repository.dart';

final class MockComunidadFeedRepository implements ComunidadFeedRepository {
  MockComunidadFeedRepository({List<ServiceItem> services = const []})
    : _services = List.unmodifiable(services);

  final List<ServiceItem> _services;

  @override
  Stream<List<ServiceItem>> watchServices({ServiceCategory? category}) =>
      Stream.value(
        List.unmodifiable(
          _services
              .where((item) => category == null || item.category == category)
              .take(30),
        ),
      );

  @override
  Stream<List<NewsItem>> watchNews() => Stream.value(const []);

  @override
  Stream<List<EventItem>> watchEvents() => Stream.value([
    EventItem(
      id: 'demo-reunion',
      title: 'Ejemplo: reunión vecinal',
      startsAt: DateTime.now().add(const Duration(days: 7)),
      place: 'Local comunal',
    ),
  ]);
}
