import '../../../create_post/domain/entities/news_post_data.dart';
import '../../../create_post/domain/entities/service_availability.dart';
import '../../../create_post/domain/entities/service_category.dart';
import '../../../create_post/domain/entities/service_post_data.dart';

final class HelpItem {
  const HelpItem({
    required this.id,
    required this.description,
    required this.authorName,
    this.title,
    this.location,
    this.peopleNeeded,
    this.fichas = 15,
    this.xp = 30,
    this.cuposTomados = 0,
    this.ayudantes = const [],
    this.estado = 'abierto',
  });

  final String id;
  final String description;
  final String authorName;
  final String? title;
  final String? location;
  final int? peopleNeeded;
  final int fichas;
  final int xp;
  final int cuposTomados;
  final List<String> ayudantes;
  final String estado;

  bool get tieneCupo =>
      (cuposTomados < (peopleNeeded ?? 1)) && estado == 'abierto';
}

final class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.title,
    required this.information,
    required this.category,
    this.price,
    this.mode,
    this.contactPhone,
    this.paymentMethods = const [],
    this.transferBanks = const [],
    this.availability,
    this.stock,
    this.photoUrls = const [],
    this.isUploading = false,
  });

  final String id;
  final String title;
  final String information;
  final ServiceCategory category;
  final num? price;
  final ServiceMode? mode;
  final String? contactPhone;
  final List<String> paymentMethods;
  final List<String> transferBanks;
  final ServiceAvailability? availability;
  final int? stock;
  final List<String> photoUrls;
  final bool isUploading;
}

final class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    this.quickCategory,
    this.createdAt,
    this.photoUrls = const [],
    this.isUploading = false,
  });

  final String id;
  final String title;
  final String content;
  final String authorName;
  final NewsTopic? quickCategory;
  final DateTime? createdAt;
  final List<String> photoUrls;
  final bool isUploading;
}

final class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.place,
    this.attendees,
    this.description,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final String place;
  final int? attendees;
  final String? description;
}

enum EventAttendanceResponse { going, notGoing }

final class EventAttendance {
  const EventAttendance({this.myResponse, this.confirmedCount = 0});

  final EventAttendanceResponse? myResponse;
  final int confirmedCount;
}
