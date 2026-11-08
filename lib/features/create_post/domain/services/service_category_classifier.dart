import '../entities/service_category.dart';

/// Regla de negocio sustituible por un fake en el controlador de Servicios.
abstract interface class ServiceCategoryClassifier {
  ServiceCategory classify({
    required String title,
    required String information,
  });
}
