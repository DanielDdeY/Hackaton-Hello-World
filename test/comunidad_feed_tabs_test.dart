import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/comunidad/data/mocks/mock_comunidad_feed_repository.dart';
import 'package:hackaton_hello_world/features/comunidad/domain/entities/comunidad_feed_items.dart';
import 'package:hackaton_hello_world/features/comunidad/domain/repositories/comunidad_feed_repository.dart';
import 'package:hackaton_hello_world/features/comunidad/presentation/pages/comunidad_page.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/news_post_data.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/service_category.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/service_post_data.dart';
import 'package:provider/provider.dart';

class _Feed implements ComunidadFeedRepository {
  final attendance = MockComunidadFeedRepository();
  final serviceRequests = <ServiceCategory?>[];
  final events = StreamController<List<EventItem>>.broadcast();
  final news = StreamController<List<NewsItem>>.broadcast();
  List<HelpItem> favors = const [];
  int newsRequests = 0;
  bool failServices = false;

  static const service = ServiceItem(
    id: 'laptop',
    title: 'Reparación de laptops',
    information: 'Diagnóstico y mantenimiento',
    category: ServiceCategory.technology,
    price: 25,
    mode: ServiceMode.provideService,
    paymentMethods: ['yape', 'bank_transfer'],
    transferBanks: ['bcp'],
    contactPhone: '987654321',
  );

  @override
  Stream<List<HelpItem>> watchFavors() => Stream.value(favors);

  @override
  Stream<HelpParticipation> watchHelpParticipation(HelpItem favor) =>
      attendance.watchHelpParticipation(favor);

  @override
  Future<void> offerHelp(String favorId) => attendance.offerHelp(favorId);

  @override
  Stream<List<ServiceItem>> watchServices({ServiceCategory? category}) {
    serviceRequests.add(category);
    if (failServices) return Stream.error(StateError('Sin conexión'));
    return Stream.value(
      category == null || category == service.category ? [service] : [],
    );
  }

  @override
  Stream<List<EventItem>> watchEvents() async* {
    yield const [];
    yield* events.stream;
  }

  @override
  Stream<List<NewsItem>> watchNews() async* {
    newsRequests++;
    yield const [];
    yield* news.stream;
  }

  @override
  Stream<EventAttendance> watchEventAttendance(String eventId) =>
      attendance.watchEventAttendance(eventId);

  @override
  Future<void> respondToEvent(
    String eventId,
    EventAttendanceResponse response,
  ) => attendance.respondToEvent(eventId, response);
}

Future<void> _open(WidgetTester tester, _Feed repository) async {
  addTearDown(repository.news.close);
  addTearDown(repository.events.close);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    Provider<ComunidadFeedRepository>.value(
      value: repository,
      child: const MaterialApp(home: ComunidadPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Favores reserva el contacto y la recompensa para el detalle', (
    tester,
  ) async {
    final repository = _Feed()
      ..favors = const [
        HelpItem(
          id: 'mudanza',
          title: 'Mudanza',
          description: 'Ayuda para mover cajas',
          authorName: 'Ana',
          hasReward: true,
          rewardDescription: 'Un almuerzo',
          contactPhone: '987654321',
        ),
        HelpItem(
          id: 'parque',
          title: 'Limpieza',
          description: 'Limpiar el parque',
          authorName: 'Luis',
        ),
      ];
    await _open(tester, repository);
    expect(find.text('Con recompensa', findRichText: true), findsNWidgets(2));
    expect(find.textContaining('Un almuerzo'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.text('WhatsApp'), findsNothing);
    expect(find.byType(SelectableText), findsNothing);
    final digitalReward = find.text(
      '+10 XP · +5 monedas (Al confirmar la ayuda)',
      findRichText: true,
    );
    expect(digitalReward, findsNothing);
    final sheet = find.byType(DraggableScrollableSheet);

    await _tap(tester, 'Mudanza');
    expect(sheet, findsOneWidget);
    expect(find.text('Un almuerzo'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).data,
      '+51 987654321',
    );
    expect(digitalReward, findsNothing);
    Navigator.of(tester.element(sheet)).pop();
    await tester.pumpAndSettle();

    await _tap(tester, 'Limpieza');
    expect(sheet, findsOneWidget);
    expect(digitalReward, findsOneWidget);
    expect(find.text('No indicado'), findsOneWidget);
    expect(find.text('WhatsApp'), findsNothing);
    Navigator.of(tester.element(sheet)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Ayudar'), findsNWidgets(2));

    await tester.tap(find.text('Ayudar').first);
    await tester.pumpAndSettle();
    expect(find.text('Ayuda ofrecida'), findsOneWidget);
    expect(find.text('Ayudar'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _open(tester, repository);
    expect(find.text('Ayuda ofrecida'), findsOneWidget);
  });

  testWidgets('Servicios filtra, conserva la selección y abre el detalle', (
    tester,
  ) async {
    final repository = _Feed();
    await _open(tester, repository);
    await _tap(tester, 'Servicios');
    expect(find.text('S/ 25.00'), findsOneWidget);
    expect(
      find.text('+15 XP cliente (+25 XP proveedor)', findRichText: true),
      findsOneWidget,
    );
    await _tap(tester, 'Reparación de laptops');
    final sheet = find.byType(DraggableScrollableSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Sin horario indicado')),
      findsOneWidget,
    );
    expect(find.text('Yape · Transferencia (BCP)'), findsOneWidget);
    final phone = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(phone.data, '987654321');
    Navigator.of(tester.element(sheet)).pop();
    await tester.pumpAndSettle();

    await _tap(tester, 'Comida');
    expect(find.text('No hay servicios en esta categoría.'), findsOneWidget);
    expect(repository.serviceRequests, [null, ServiceCategory.food]);
    await _tap(tester, 'Eventos');
    await _tap(tester, 'Servicios');
    expect(find.text('No hay servicios en esta categoría.'), findsOneWidget);
    expect(repository.serviceRequests, [null, ServiceCategory.food]);
    await _tap(tester, 'Todos');
    expect(find.text('Reparación de laptops'), findsOneWidget);
    expect(repository.serviceRequests.last, isNull);
  });

  testWidgets('Servicios permite reintentar una consulta fallida', (
    tester,
  ) async {
    final repository = _Feed()..failServices = true;
    await _open(tester, repository);
    await _tap(tester, 'Servicios');
    expect(find.text('No se pudieron cargar los servicios.'), findsOneWidget);
    repository.failServices = false;
    await _tap(tester, 'Reintentar');
    expect(find.text('Reparación de laptops'), findsOneWidget);
    expect(repository.serviceRequests, [null, null]);
  });

  testWidgets('Eventos muestra nuevas noticias y mantiene la suscripción', (
    tester,
  ) async {
    final repository = _Feed();
    await _open(tester, repository);
    await _tap(tester, 'Eventos');
    expect(find.text('Próximos eventos'), findsOneWidget);
    expect(find.text('Aún no hay eventos programados'), findsOneWidget);
    expect(find.text('Noticias del barrio'), findsOneWidget);
    expect(find.text('Aún no hay noticias del barrio.'), findsOneWidget);

    repository.events.add([
      EventItem(
        id: 'reunion',
        title: 'Reunión de la junta vecinal',
        place: 'Local comunal',
        startsAt: DateTime(2099, 11, 9, 17, 30),
        description: 'Coordinaremos el simulacro.',
        attendees: 14,
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Reunión de la junta vecinal'), findsOneWidget);
    expect(find.text('NOV'), findsOneWidget);
    expect(find.text('17:30'), findsOneWidget);
    expect(find.text('Local comunal'), findsOneWidget);
    expect(find.text('14 asistentes previstos'), findsOneWidget);
    expect(
      find.text('+10 XP (+3 monedas al marcar «Voy»)', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Aún no hay eventos programados'), findsNothing);

    await _tap(tester, 'Detalles');
    final eventSheet = find.byType(DraggableScrollableSheet);
    expect(
      find.descendant(
        of: eventSheet,
        matching: find.text('Coordinaremos el simulacro.'),
      ),
      findsOneWidget,
    );
    Navigator.of(tester.element(eventSheet)).pop();
    await tester.pumpAndSettle();

    await _tap(tester, 'Asistencia');
    await _tap(tester, 'Voy');
    expect(find.text('1 asistencia confirmada'), findsOneWidget);
    await _tap(tester, 'Voy');
    await _tap(tester, 'No voy');
    expect(find.text('0 asistencias confirmadas'), findsOneWidget);

    final item = NewsItem(
      id: 'aviso',
      title: 'Mantenimiento de la plaza',
      content: 'La plaza estará cerrada durante la mañana.',
      authorName: 'Elena',
      quickCategory: NewsTopic.worksOrOutages,
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
    );
    repository.news.add([item]);
    await tester.pumpAndSettle();
    expect(find.text('hace 2 h'), findsOneWidget);
    expect(find.text('Obras o cortes de servicio'), findsOneWidget);
    await _tap(tester, item.title);
    final sheet = find.byType(DraggableScrollableSheet);
    expect(
      find.descendant(of: sheet, matching: find.text(item.content)),
      findsOneWidget,
    );
    Navigator.of(tester.element(sheet)).pop();
    await tester.pumpAndSettle();

    await _tap(tester, 'Vecinos');
    await _tap(tester, 'Eventos');
    expect(find.text(item.title), findsOneWidget);
    expect(repository.newsRequests, 1);
  });
}
