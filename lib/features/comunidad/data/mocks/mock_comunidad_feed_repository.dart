import 'dart:async';

import '../../../create_post/domain/entities/service_category.dart';
import '../../domain/entities/comunidad_feed_items.dart';
import '../../domain/repositories/comunidad_feed_repository.dart';

final class MockComunidadFeedRepository implements ComunidadFeedRepository {
  MockComunidadFeedRepository({
    List<ServiceItem> services = const [],
    List<HelpItem> favors = const [],
  }) : _services = List.unmodifiable(services),
       _favors = List.unmodifiable(favors);

  final List<ServiceItem> _services;
  final List<HelpItem> _favors;
  final _responses = <String, EventAttendanceResponse>{};
  final _responseChanges = StreamController<String>.broadcast();

  @override
  Stream<List<HelpItem>> watchFavors() => Stream.value(_favors);

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

  @override
  Stream<EventAttendance> watchEventAttendance(String eventId) async* {
    yield _attendance(eventId);
    yield* _responseChanges.stream
        .where((id) => id == eventId)
        .map((_) => _attendance(eventId));
  }

  @override
  Future<void> respondToEvent(
    String eventId,
    EventAttendanceResponse response,
  ) async {
    _responses[eventId] = response;
    _responseChanges.add(eventId);
  }

  @override
  Future<void> postularAFavor(String postId) async {}

  @override
  Future<void> marcarFavorTerminado(String postId) async {}

  @override
  Future<void> confirmarFavor(String postId) async {}

  EventAttendance _attendance(String eventId) {
    final response = _responses[eventId];
    return EventAttendance(
      myResponse: response,
      confirmedCount: response == EventAttendanceResponse.going ? 1 : 0,
    );
  }
}
