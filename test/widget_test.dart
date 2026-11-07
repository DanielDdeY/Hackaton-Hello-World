import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hackaton_hello_world/features/create_post/presentation/widgets/category_card.dart';
import 'package:hackaton_hello_world/main.dart';
import 'package:hackaton_hello_world/screens/map/map_screen.dart';
import 'package:hackaton_hello_world/screens/map/widgets/location_permission_view.dart';

void main() {
  testWidgets('Opens the category grid from the active destination', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MyApp());

    final bar = find.byType(BottomAppBar);
    expect(find.text('Resumen de tu barrio'), findsOneWidget);

    // La pestaña Mapa muestra MapScreen. Sin permiso de ubicación el mapa
    // queda bloqueado en la vista de permisos.
    expect(find.byType(MapScreen), findsNothing);
    await tester.tap(find.descendant(of: bar, matching: find.text('Mapa')));
    await tester.pumpAndSettle();
    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.byType(LocationPermissionView), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);

    // Verifica la pestaña de Comunidad
    await tester.tap(find.descendant(of: bar, matching: find.text('Comunidad')));
    await tester.pumpAndSettle();
    expect(find.text('Favores'), findsOneWidget);

    // Verifica la pestaña de Inicio
    await tester.tap(find.descendant(of: bar, matching: find.text('Inicio')));
    await tester.pumpAndSettle();
    expect(find.text('Resumen de tu barrio'), findsOneWidget);

    // Verifica la pestaña de Ayuda
    await tester.tap(find.descendant(of: bar, matching: find.text('Ayuda')));
    await tester.pumpAndSettle();
    expect(find.text('Encuentra orientación y apoyo'), findsOneWidget);

    expect(find.byType(CategoryCard), findsNothing);
    await tester.tap(find.byTooltip('Publicar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué deseas publicar hoy?'), findsOneWidget);
    expect(find.text('Selecciona una categoría'), findsOneWidget);
    expect(find.byType(CategoryCard), findsNWidgets(4));

    const categories = ['Emergencia', 'Ayuda', 'Servicios', 'Noticias'];
    final positions = [
      for (final label in categories) tester.getTopLeft(find.text(label)),
    ];
    expect(positions[0].dy, positions[1].dy);
    expect(positions[2].dy, positions[3].dy);
    expect(positions[0].dx, positions[2].dx);
    expect(positions[1].dx, positions[3].dx);
    expect(positions[0].dy, lessThan(positions[2].dy));

    for (final label in categories) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, label), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryCard), findsNothing);
    expect(find.text('Encuentra orientación y apoyo'), findsOneWidget);
  });

  testWidgets('Keeps all category cards reachable with enlarged text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MyApp());
    await tester.tap(find.byTooltip('Publicar'));
    await tester.pumpAndSettle();

    final news = find.text('Noticias');
    await tester.ensureVisible(news);
    await tester.pumpAndSettle();
    expect(news.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
