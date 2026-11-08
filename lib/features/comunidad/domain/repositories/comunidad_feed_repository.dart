import '../../../create_post/domain/entities/service_category.dart';
import '../entities/comunidad_feed_items.dart';

abstract interface class ComunidadFeedRepository {
  Stream<List<ServiceItem>> watchServices({ServiceCategory? category});
  Stream<List<NewsItem>> watchNews();
  Stream<List<EventItem>> watchEvents();
}
