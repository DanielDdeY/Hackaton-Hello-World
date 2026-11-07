enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

final class ServiceAvailability {
  ServiceAvailability({
    required Set<Weekday> days,
    required this.startMinute,
    required this.endMinute,
  }) : days = Set.unmodifiable(days);

  final Set<Weekday> days;
  final int? startMinute;
  final int? endMinute;

  bool get isValid {
    final start = startMinute;
    final end = endMinute;
    return days.isNotEmpty &&
        start != null &&
        end != null &&
        start >= 0 &&
        end < Duration.minutesPerDay &&
        end > start;
  }
}
