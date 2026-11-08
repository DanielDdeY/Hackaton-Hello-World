import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../create_post/domain/entities/news_post_data.dart';
import '../../../create_post/domain/entities/service_availability.dart';
import '../../../create_post/domain/entities/service_category.dart';
import '../../../create_post/domain/entities/service_post_data.dart';
import '../../../create_post/domain/services/auth_gateway.dart';
import '../../domain/entities/comunidad_feed_items.dart';
import '../../domain/repositories/comunidad_feed_repository.dart';

final class FirestoreComunidadFeedRepository
    implements ComunidadFeedRepository {
  const FirestoreComunidadFeedRepository({
    required this._firestore,
    required this._auth,
  });

  final FirebaseFirestore _firestore;
  final AuthGateway _auth;

  static const _eventDateField = 'details.startsAt';
  static const _feedLimit = 30;

  @override
  Stream<List<HelpItem>> watchFavors() => _watchPosts('help', _readHelp);

  @override
  Stream<List<ServiceItem>> watchServices({ServiceCategory? category}) =>
      _watchPosts('service', _readService, serviceCategory: category);

  @override
  Stream<List<NewsItem>> watchNews() => _watchPosts('news', _readNews);

  @override
  Stream<List<EventItem>> watchEvents() async* {
    try {
      await for (final items in _watchPosts('event', _readEvent)) {
        yield items;
      }
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') rethrow;

      // Si el índice compuesto aún no está disponible, consulta solo la fecha.
      // Filtra las publicaciones activas antes de limitar el resultado.
      yield* _firestore
          .collection('posts')
          .where(_eventDateField, isGreaterThan: Timestamp.now())
          .orderBy(_eventDateField)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => _readEvent(doc.id, doc.data()))
                .whereType<EventItem>()
                .take(_feedLimit)
                .toList(growable: false),
          );
    }
  }

  @override
  Stream<EventAttendance> watchEventAttendance(String eventId) async* {
    final uid = await _auth.ensureSignedIn();
    final answers = EventAttendanceResponse.values.asNameMap();
    yield* _eventResponses(eventId).snapshots().map((snapshot) {
      var confirmedCount = 0;
      EventAttendanceResponse? myResponse;
      for (final doc in snapshot.docs) {
        final response = answers[doc.data()['response']];
        if (response == EventAttendanceResponse.going) confirmedCount++;
        if (doc.id == uid) myResponse = response;
      }
      return EventAttendance(
        myResponse: myResponse,
        confirmedCount: confirmedCount,
      );
    });
  }

  @override
  Future<void> respondToEvent(
    String eventId,
    EventAttendanceResponse response,
  ) async {
    final uid = await _auth.ensureSignedIn();
    await _eventResponses(eventId).doc(uid).set({
      'response': response.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> postularAFavor(String postId) async {
    final uid = await _auth.ensureSignedIn();
    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) throw StateError('El pedido de ayuda ya no existe.');
      final data = snapshot.data() ?? {};
      final details = Map<String, dynamic>.from(data['details'] as Map? ?? {});

      final ayudantes = List<String>.from((details['ayudantes'] as List?)?.whereType<String>() ?? []);
      if (ayudantes.contains(uid)) return;

      final int cuposTotales = (details['cuposTotales'] as num?)?.toInt() ??
          (details['peopleNeeded'] as num?)?.toInt() ?? 1;
      int cuposTomados = (details['cuposTomados'] as num?)?.toInt() ?? 0;

      if (cuposTomados >= cuposTotales) {
        throw StateError('Todos los cupos de ayudantes han sido tomados.');
      }

      ayudantes.add(uid);
      cuposTomados++;
      final nuevoEstado = cuposTomados >= cuposTotales ? 'cuposLlenos' : 'abierto';

      details['ayudantes'] = ayudantes;
      details['cuposTomados'] = cuposTomados;
      details['estado'] = nuevoEstado;

      transaction.update(postRef, {
        'details': details,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> marcarFavorTerminado(String postId) async {
    await _auth.ensureSignedIn();
    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};
      final details = Map<String, dynamic>.from(data['details'] as Map? ?? {});

      details['estado'] = 'esperandoConfirmacion';
      transaction.update(postRef, {
        'details': details,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> confirmarFavor(String postId) async {
    await _auth.ensureSignedIn();
    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};
      final details = Map<String, dynamic>.from(data['details'] as Map? ?? {});

      details['estado'] = 'completado';
      transaction.update(postRef, {
        'details': details,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  CollectionReference<Map<String, dynamic>> _eventResponses(String eventId) =>
      _firestore.collection('posts').doc(eventId).collection('attendance');

  Stream<List<T>> _watchPosts<T>(
    String category,
    T? Function(String, Map<String, dynamic>) decode, {
    ServiceCategory? serviceCategory,
  }) async* {
    await _auth.ensureSignedIn();

    var query = _firestore
        .collection('posts')
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: 'active');
    if (serviceCategory != null) {
      query = query.where(
        'details.serviceCategory',
        isEqualTo: serviceCategory.key,
      );
    }
    final upcoming = category == 'event';
    final orderField = upcoming ? _eventDateField : 'createdAt';
    if (upcoming) {
      query = query.where(orderField, isGreaterThan: Timestamp.now());
    }

    yield* query
        .orderBy(orderField, descending: !upcoming)
        .limit(_feedLimit)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) ?decode(doc.id, doc.data()),
          ],
        );
  }

  static HelpItem? _readHelp(String id, Map<String, dynamic> data) {
    final details = data['details'];
    if (details is! Map) return null;
    final description = _text(details['description']);
    if (description == null) return null;

    final people = details['peopleNeeded'];
    final count = people is int && people > 0 ? people.clamp(1, 300) : 1;
    final fichas = (details['fichasRecompensa'] as num?)?.toInt() ?? (count > 2 ? 30 : 15);
    final xp = (details['xpRecompensa'] as num?)?.toInt() ?? (count > 2 ? 60 : 30);
    final cuposTomados = (details['cuposTomados'] as num?)?.toInt() ?? 0;
    final ayudantes = (details['ayudantes'] as List?)?.whereType<String>().toList() ?? const <String>[];
    final estado = details['estado'] as String? ?? 'abierto';

    final location = data['location'];
    final autoLocation =
        location is Map &&
        location['addressEditedByUser'] != true &&
        (location['source'] == 'gps' || location['source'] == 'gps_last_known');

    return HelpItem(
      id: id,
      description: description,
      authorName: _text(data['authorName']) ?? 'Vecino',
      authorId: _text(data['authorId']),
      title: _text(details['title']),
      location: autoLocation ? null : _text(details['specificLocation']),
      peopleNeeded: people is int && people > 0 ? count : null,
      fichas: fichas,
      xp: xp,
      cuposTomados: cuposTomados,
      ayudantes: ayudantes,
      estado: estado,
    );
  }

  static ServiceItem? _readService(String id, Map<String, dynamic> data) {
    final details = data['details'];
    if (details is! Map) return null;
    final title = _text(details['title']);
    final information = _text(details['information']);
    if (title == null || information == null) return null;
    final price = details['price'];
    final mode = switch (details['mode']) {
      'provide_service' => ServiceMode.provideService,
      'sell' => ServiceMode.sell,
      _ => null,
    };
    final stock = details['stock'];

    return ServiceItem(
      id: id,
      title: title,
      information: information,
      category: ServiceCategory.values.firstWhere(
        (category) => category.key == details['serviceCategory'],
        orElse: () => ServiceCategory.other,
      ),
      price: price is num && price.isFinite && price >= 0 ? price : null,
      mode: mode,
      contactPhone: _text(details['contactPhone']),
      paymentMethods: _strings(details['paymentMethods']),
      transferBanks: _strings(details['transferBanks']),
      availability: mode == ServiceMode.provideService
          ? _availability(details['availability'])
          : null,
      stock: mode == ServiceMode.sell && stock is int && stock > 0
          ? stock
          : null,
      photoUrls: _photos(data['photos']),
      isUploading: data['mediaStatus'] == 'uploading',
    );
  }

  static NewsItem? _readNews(String id, Map<String, dynamic> data) {
    final details = data['details'];
    if (details is! Map) return null;
    final title = _text(details['title']);
    final content = _text(details['content']);
    if (title == null || content == null) return null;
    final timestamp = data['createdAt'];

    return NewsItem(
      id: id,
      title: title,
      content: content,
      authorName: _text(data['authorName']) ?? 'Vecino',
      quickCategory: switch (details['quickCategory']) {
        'general' => NewsTopic.generalNotice,
        'lost_pet' => NewsTopic.lostPet,
        'neighborhood_life' => NewsTopic.neighborhoodLife,
        'service_cuts' => NewsTopic.worksOrOutages,
        _ => null,
      },
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
      photoUrls: _photos(data['photos']),
      isUploading: data['mediaStatus'] == 'uploading',
    );
  }

  static EventItem? _readEvent(String id, Map<String, dynamic> data) {
    if (data['category'] != 'event' || data['status'] != 'active') return null;
    final details = data['details'];
    if (details is! Map) return null;
    final title = _text(details['title']);
    final place = _text(details['place']);
    final startsAt = details['startsAt'];
    if (title == null || place == null || startsAt is! Timestamp) return null;
    final attendees = details['attendees'];

    return EventItem(
      id: id,
      title: title,
      place: place,
      startsAt: startsAt.toDate(),
      attendees: attendees is int && attendees >= 0 ? attendees : null,
      description: _text(details['description']),
    );
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _strings(Object? value) =>
      value is List ? List.unmodifiable(value.whereType<String>()) : const [];

  static List<String> _photos(Object? value) {
    if (value is! List) return const [];
    return List.unmodifiable([
      for (final photo in value)
        if (photo is Map) ?_text(photo['downloadUrl']),
    ]);
  }

  static ServiceAvailability? _availability(Object? value) {
    if (value is! Map) return null;
    final days = _strings(value['days']).toSet();
    final availability = ServiceAvailability(
      days: {
        for (final day in Weekday.values)
          if (days.contains(day.name.substring(0, 3))) day,
      },
      startMinute: _minutes(value['startTime']),
      endMinute: _minutes(value['endTime']),
    );
    return availability.isValid ? availability : null;
  }

  static final _timePattern = RegExp(r'^([01][0-9]|2[0-3]):([0-5][0-9])$');

  static int? _minutes(Object? value) {
    final match = value is String ? _timePattern.firstMatch(value) : null;
    if (match == null) return null;
    return int.parse(match[1]!) * 60 + int.parse(match[2]!);
  }
}
