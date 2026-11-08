import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/comunidad/data/mocks/mock_comunidad_feed_repository.dart';
import 'package:hackaton_hello_world/features/comunidad/domain/entities/comunidad_feed_items.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/service_category.dart';

void main() {
  test('filtra los servicios por categoría y admite el filtro Todos', () async {
    const food = ServiceItem(
      id: 'menu',
      title: 'Menú casero',
      information: 'Almuerzo por encargo',
      category: ServiceCategory.food,
    );
    const tech = ServiceItem(
      id: 'laptop',
      title: 'Reparación de laptops',
      information: 'Formateo y antivirus',
      category: ServiceCategory.technology,
    );
    final repository = MockComunidadFeedRepository(services: [food, tech]);

    expect(await repository.watchServices().first, [food, tech]);
    expect(
      await repository
          .watchServices(category: ServiceCategory.technology)
          .first,
      [tech],
    );
    expect(
      await repository.watchServices(category: ServiceCategory.pets).first,
      isEmpty,
    );
  });
}
