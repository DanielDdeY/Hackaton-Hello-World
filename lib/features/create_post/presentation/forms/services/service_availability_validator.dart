import '../../../domain/entities/service_availability.dart';

abstract final class ServiceAvailabilityValidator {
  static String? validate(ServiceAvailability? availability) {
    if (availability == null || availability.isValid) return null;
    if (availability.days.isEmpty) return 'Selecciona al menos un día.';
    if (availability.startMinute == null || availability.endMinute == null) {
      return 'Indica la hora de inicio y la hora de fin.';
    }
    return 'La hora de fin debe ser posterior a la hora de inicio.';
  }
}
