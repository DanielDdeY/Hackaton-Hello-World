import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/comunidad/data/mocks/mock_comunidad_feed_repository.dart';
import 'package:hackaton_hello_world/features/comunidad/domain/entities/comunidad_feed_items.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/service_category.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/service_post_data.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/auth_gateway.dart';
import 'package:hackaton_hello_world/features/economy/domain/services/period_provider.dart';
import 'package:hackaton_hello_world/features/notifications/domain/publication_activity.dart';
import 'package:hackaton_hello_world/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthGateway implements AuthGateway {
  const _TestAuthGateway({this.displayName});

  final String? displayName;

  @override
  String? get currentUid => 'test-user';

  @override
  String? get currentDisplayName => displayName;

  @override
  Future<String> ensureSignedIn() async => 'test-user';

  @override
  Future<String> signInWithGoogle() async => 'test-user';

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPhoneCode(String phoneNumber) async {}

  @override
  Future<String> signInWithPhoneCode(String code) async => 'test-user';
}

class _TestPublicationActivity implements PublicationActivityRepository {
  final updates = StreamController<List<PublicationActivity>>.broadcast();
  final requests = <String>{};

  @override
  Stream<List<PublicationActivity>> watchReceived() => updates.stream;

  @override
  Future<bool> requestService(String postId) async => requests.add(postId);

  @override
  Stream<List<ServiceRequest>> watchServiceRequests(
    String postId, {
    required bool asProvider,
  }) => Stream.value(const []);

  @override
  Future<void> markServiceDelivered({
    required String postId,
    required String requesterUid,
  }) async {}
}

void main() {
  testWidgets(
    'la campana muestra la actividad y Servicios registra solicitudes',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'vecino_departamento': 'Lima',
        'vecino_provincia': 'Lima',
        'vecino_distrito': 'Miraflores',
        'tutorial_inicio_v1_visto': true,
      });
      final activity = _TestPublicationActivity();
      addTearDown(activity.updates.close);
      await tester.pumpWidget(
        MyApp(
          publicationActivityRepository: activity,
          comunidadFeedRepository: MockComunidadFeedRepository(
            services: const [
              ServiceItem(
                id: 'electricista',
                title: 'Electricista',
                information: 'Instalaciones',
                category: ServiceCategory.homeTrades,
                mode: ServiceMode.provideService,
                contactPhone: '987654321',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pump();
      expect(activity.updates.hasListener, isTrue);
      const offer = PublicationActivity(
        kind: PublicationActivityKind.helpOffer,
        actorName: 'Ana',
        postTitle: 'Mover cajas',
        occurredAt: null,
      );
      const attendance = PublicationActivity(
        kind: PublicationActivityKind.eventAttendance,
        actorName: 'Luis',
        postTitle: 'Reunión',
        occurredAt: null,
      );
      const request = PublicationActivity(
        kind: PublicationActivityKind.serviceRequest,
        actorName: 'Rosa',
        postTitle: 'Gasfitería',
        occurredAt: null,
      );
      activity.updates.add(const [offer, attendance, request]);
      await tester.pumpAndSettle();
      expect(find.text('Ana se ofreció a ayudarte'), findsOneWidget);
      expect(find.text('Luis confirmó asistencia'), findsOneWidget);
      expect(find.text('Rosa solicitó tu servicio'), findsOneWidget);

      activity.updates.add(const [offer, request]);
      await tester.pumpAndSettle();
      expect(find.text('Luis confirmó asistencia'), findsNothing);
      Navigator.of(tester.element(find.text('Notificaciones'))).pop();
      await tester.pumpAndSettle();
      expect(activity.updates.hasListener, isFalse);

      await tester.tap(find.text('Comunidad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Servicios'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contratar'));
      await tester.pumpAndSettle();
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Llamar'), findsNothing);
      expect(activity.requests, isEmpty);
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();
      expect(activity.requests, {'electricista'});
      expect(find.text('Solicitud enviada al anunciante.'), findsOneWidget);
    },
  );

  testWidgets('publica el periodo simulado y notifica sus cambios', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final periods = SimulatablePeriodProvider(
      base: FakePeriodProvider('2026-12'),
    );
    addTearDown(periods.dispose);
    await tester.pumpWidget(MyApp(periodProvider: periods));
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Consumer<PeriodProvider>(
          builder: (_, periods, _) => Text(periods.currentPeriod),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2026-12'), findsOneWidget);

    periods.simulateNextMonth();
    await tester.pump();
    expect(find.text('2027-01'), findsOneWidget);

    periods.clearSimulation();
    await tester.pump();
    expect(find.text('2026-12'), findsOneWidget);
  });

  testWidgets('muestra la bienvenida de AyniVeci', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Hola, vecino'), findsOneWidget);
    expect(find.text('Continuar con celular'), findsOneWidget);
  });

  testWidgets('muestra el inicio guardado del vecino', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vecino_departamento': 'Lima',
      'vecino_provincia': 'Lima',
      'vecino_distrito': 'Miraflores',
    });
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    expect(find.text('AYNI VECI'), findsOneWidget);
    expect(find.text('Carlos Mendoza'), findsOneWidget);
    expect(find.text('Mascota bloqueada'), findsOneWidget);

    await tester.tap(find.text('Ayuda').last);
    await tester.pumpAndSettle();
    expect(find.text('Mochila de Emergencia'), findsOneWidget);
    expect(find.text('Prepárate para un simulacro'), findsOneWidget);
  });

  testWidgets('permite buscar ubicaciones y limpia niveles dependientes', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MyApp(authGateway: _TestAuthGateway(displayName: 'Ana García')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seleccionar').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'lima');
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seleccionar').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'lima');
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seleccionar').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'miraflores');
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Revisar distrito'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar y conocer la app'));
    await tester.pumpAndSettle();

    expect(find.text('Seleccionar'), findsNothing);
    expect(find.text('Ana García'), findsOneWidget);
  });
}
