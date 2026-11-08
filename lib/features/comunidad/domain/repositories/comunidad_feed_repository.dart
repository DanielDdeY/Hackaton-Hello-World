import '../../../create_post/domain/entities/service_category.dart';
import '../entities/comunidad_feed_items.dart';

abstract interface class ComunidadFeedRepository {
  Stream<List<HelpItem>> watchFavors();
  Stream<List<ServiceItem>> watchServices({ServiceCategory? category});
  Stream<List<NewsItem>> watchNews();
  Stream<List<EventItem>> watchEvents();
  Stream<EventAttendance> watchEventAttendance(String eventId);
  Future<void> respondToEvent(String eventId, EventAttendanceResponse response);
  Future<void> postularAFavor(String postId);
  Future<void> marcarFavorTerminado(String postId);
  Future<void> confirmarFavor(String postId);
}
