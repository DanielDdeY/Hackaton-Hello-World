import '../../../create_post/domain/entities/service_category.dart';
import '../entities/comunidad_feed_items.dart';

abstract interface class ComunidadFeedRepository {
  Stream<List<HelpItem>> watchFavors();
  Stream<HelpParticipation> watchHelpParticipation(HelpItem favor);
  Future<void> offerHelp(String favorId);
  Stream<List<ServiceItem>> watchServices({ServiceCategory? category});
  Stream<List<NewsItem>> watchNews();
  Stream<List<EventItem>> watchEvents();
  Stream<EventAttendance> watchEventAttendance(String eventId);
  Future<void> respondToEvent(String eventId, EventAttendanceResponse response);
}
