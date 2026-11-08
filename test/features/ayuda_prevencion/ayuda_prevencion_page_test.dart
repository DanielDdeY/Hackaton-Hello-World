import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hackaton_hello_world/features/ayuda_prevencion/ayuda_prevencion_page.dart';
import 'package:hackaton_hello_world/features/ayuda_prevencion/data/peru_emergency_numbers.dart';
import 'package:hackaton_hello_world/features/ayuda_prevencion/services/backpack_checklist_store.dart';
import 'package:hackaton_hello_world/features/ayuda_prevencion/widgets/simulacro_video_page.dart';
import 'package:hackaton_hello_world/features/economy/domain/models/economy_result.dart';
import 'package:hackaton_hello_world/features/economy/domain/services/economy_engine.dart';

/// Motor falso: registra las llamadas y devuelve (o lanza) lo configurado.
class _FakeEngine implements EconomyEngine {
  _FakeEngine({this.failure, this.alreadyApplied = false});

  final EconomyFailure? failure;
  final bool alreadyApplied;
  final awards = <({EconomySource source, String sourceId})>[];

  @override
  String newOperationId() => 'operation-backpack-0001';

  @override
  Future<EconomyResult> award({
    required EconomySource source,
    required String sourceId,
    required String operationId,
    int? rating,
  }) async {
    awards.add((source: source, sourceId: sourceId));
    if (failure != null) throw failure!;
    return EconomyResult(
      confirmationId: 'backpack_verified_$sourceId',
      period: '2026-11',
      slot: 1,
      alreadyApplied: alreadyApplied,
      clientXp: EconomyResult.backpackXp,
      providerXp: 0,
      coins: EconomyResult.backpackCoins,
    );
  }

  @override
  Future<EconomyResult> confirmService({
    required String postId,
    required int rating,
    required String operationId,
  }) => throw UnimplementedError();

  @override
  Future<void> confirmFavor({
    required String postId,
    required String helperUid,
  }) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    AyudaPrevencionPage page = const AyudaPrevencionPage(),
    EconomyEngine? engine,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      Provider<EconomyEngine?>.value(
        value: engine,
        child: MaterialApp(home: Scaffold(body: page)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> marcarTodosLosProductos(WidgetTester tester) async {
    for (final item in BackpackChecklistStore.defaultItems) {
      await tester.tap(find.widgetWithText(FilterChip, item));
      await tester.pumpAndSettle();
    }
  }

  const botonBono = 'Reclamar bono de preparación (+50 fichas, +100 XP)';

  testWidgets('renderiza las tres secciones principales', (tester) async {
    await pumpPage(tester);

    expect(find.text('Mochila de Emergencia'), findsOneWidget);
    expect(find.text('Tutorial Paso a Paso'), findsOneWidget);
    expect(find.textContaining('Directorio de Emergencia'), findsOneWidget);
    expect(find.text('Cerca de ti'), findsOneWidget);
  });

  testWidgets('muestra y permite marcar los productos de la mochila', (
    tester,
  ) async {
    await pumpPage(tester);

    final chip = find.widgetWithText(FilterChip, 'Agua');
    expect(chip, findsOneWidget);
    expect(
      find.byType(FilterChip),
      findsNWidgets(BackpackChecklistStore.defaultItems.length),
    );

    await marcarTodosLosProductos(tester);
    expect(find.text('Mochila completa'), findsOneWidget);
    expect(find.text('Validado por Jefe de Grupo'), findsNothing);
    expect(find.text(botonBono), findsOneWidget);
  });

  testWidgets('reclama el bono con el motor y recuerda la marca local', (
    tester,
  ) async {
    final engine = _FakeEngine();
    await pumpPage(tester, engine: engine);
    await marcarTodosLosProductos(tester);

    await tester.tap(find.text(botonBono));
    await tester.pumpAndSettle();

    expect(engine.awards, [
      (source: EconomySource.backpackVerified, sourceId: 'mochila'),
    ]);
    expect(
      find.text('Insignia "Vecino preparado" obtenida'),
      findsOneWidget,
    );
    expect(find.textContaining('+50 fichas y +100 XP'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('mochila_bono_reclamado_v1'), isTrue);
    expect(prefs.getStringList('vecino_insignias'), contains('vecino-preparado'));
    // El saldo lo escribe solo el servidor: nunca se suman puntos en local.
    expect(prefs.getInt('vecino_fichas'), isNull);
    expect(prefs.getInt('vecino_xp'), isNull);
  });

  testWidgets('avisa si el bono ya estaba reclamado en el servidor', (
    tester,
  ) async {
    final engine = _FakeEngine(alreadyApplied: true);
    await pumpPage(tester, engine: engine);
    await marcarTodosLosProductos(tester);

    await tester.tap(find.text(botonBono));
    await tester.pumpAndSettle();

    expect(
      find.text('Tu bono de preparación ya estaba reclamado.'),
      findsOneWidget,
    );
    expect(
      find.text('Insignia "Vecino preparado" obtenida'),
      findsOneWidget,
    );
  });

  testWidgets('no marca el bono como reclamado si el servidor lo rechaza', (
    tester,
  ) async {
    final engine = _FakeEngine(
      failure: const EconomyFailure(EconomyFailureReason.permissionDenied),
    );
    await pumpPage(tester, engine: engine);
    await marcarTodosLosProductos(tester);

    await tester.tap(find.text(botonBono));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo autorizar'), findsOneWidget);
    expect(find.text(botonBono), findsOneWidget);
    expect(
      find.text('Insignia "Vecino preparado" obtenida'),
      findsNothing,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('mochila_bono_reclamado_v1'), isNull);
    expect(prefs.getStringList('vecino_insignias'), isNull);
  });

  testWidgets('pide iniciar sesion si no hay motor de economia', (
    tester,
  ) async {
    await pumpPage(tester);
    await marcarTodosLosProductos(tester);

    await tester.tap(find.text(botonBono));
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión para reclamar el bono.'), findsOneWidget);
    expect(find.text(botonBono), findsOneWidget);
  });

  testWidgets('conserva los productos guardados al ampliar el checklist', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'mochila_checklist_v1': ['Agua', 'Radio'],
    });
    await pumpPage(tester);

    final waterChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Agua'),
    );
    final newProductChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Silbato'),
    );

    expect(waterChip.selected, isTrue);
    expect(newProductChip.selected, isFalse);
    expect(
      find.text(
        '2 de ${BackpackChecklistStore.defaultItems.length} elementos listos',
      ),
      findsOneWidget,
    );
  });

  testWidgets('el botón de simulacro abre el video dentro de la app', (
    tester,
  ) async {
    await pumpPage(
      tester,
      page: AyudaPrevencionPage(
        simulacroPageBuilder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Simulacro de emergencia')),
          body: const Text('Prepárate practicando'),
        ),
      ),
    );

    await tester.tap(find.text('Prepárate para un simulacro'));
    await tester.pumpAndSettle();

    expect(find.text('Simulacro de emergencia'), findsOneWidget);
    expect(find.text('Prepárate practicando'), findsOneWidget);
    expect(SimulacroVideoPage.videoId, 'f9h9EIuuWs8');
  });

  testWidgets('muestra los teléfonos de emergencia nacionales', (tester) async {
    await pumpPage(tester);

    for (final contact in PeruEmergencyNumbers.contacts) {
      if (contact.phoneNumber == null) continue;
      expect(
        find.text(contact.phoneNumber!),
        findsWidgets,
        reason: 'Falta el número de ${contact.name}',
      );
    }
    // La Brigada Vecinal aún no tiene teléfono (irá desde Firestore).
    expect(find.text('Brigada Vecinal'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('la búsqueda cercana muestra estado inicial sin GPS', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.textContaining('Presiona "Buscar"'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
  });
}
