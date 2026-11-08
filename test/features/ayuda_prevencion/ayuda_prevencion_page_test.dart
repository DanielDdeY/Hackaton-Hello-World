import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hackaton_hello_world/features/ayuda_prevencion/ayuda_prevencion_page.dart';
import 'package:hackaton_hello_world/features/ayuda_prevencion/data/peru_emergency_numbers.dart';
import 'package:hackaton_hello_world/features/ayuda_prevencion/services/backpack_checklist_store.dart';
import 'package:hackaton_hello_world/features/ayuda_prevencion/widgets/simulacro_video_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    AyudaPrevencionPage page = const AyudaPrevencionPage(),
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
    await tester.pumpAndSettle();
  }

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

    for (final item in BackpackChecklistStore.defaultItems) {
      await tester.tap(find.widgetWithText(FilterChip, item));
      await tester.pumpAndSettle();
    }
    expect(find.text('Validado por Jefe de Grupo'), findsOneWidget);
    expect(
      find.text('Reclamar bono de preparación (+50 fichas, +100 XP)'),
      findsOneWidget,
    );

    await tester.tap(
      find.text('Reclamar bono de preparación (+50 fichas, +100 XP)'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Insignia "Vecino preparado" obtenida'),
      findsOneWidget,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('mochila_bono_reclamado_v1'), isTrue);
    expect(prefs.getInt('vecino_fichas'), 50);
    expect(prefs.getInt('vecino_xp'), 100);
    expect(prefs.getStringList('vecino_insignias'), contains('vecino-preparado'));
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
