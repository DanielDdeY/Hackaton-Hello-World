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

  @override
  Stream<List<ServiceItem>> watchServices({ServiceCategory? category}) =>
      _watchPosts('service', _readService, serviceCategory: category);

  @override
  Stream<List<NewsItem>> watchNews() => _watchPosts('news', _readNews);

  @override
  Stream<List<EventItem>> watchEvents() => Stream.value(const []);

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

    yield* query
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) ?decode(doc.id, doc.data()),
          ],
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
