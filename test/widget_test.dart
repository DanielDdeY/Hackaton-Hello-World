import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hackaton_hello_world/main.dart';
import 'package:hackaton_hello_world/screens/map/map_screen.dart';
import 'package:hackaton_hello_world/screens/map/widgets/location_permission_view.dart';

void main() {
  testWidgets('Switches destinations and opens the publish sheet', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());

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

    for (final (label, description) in [
      ('Comunidad', 'Conecta con tus vecinos'),
      ('Ayuda', 'Encuentra orientación y apoyo'),
      ('Inicio', 'Resumen de tu barrio'),
    ]) {
      await tester.tap(find.descendant(of: bar, matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(find.text(description), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Publicar'));
    await tester.pumpAndSettle();
    expect(find.text('Publicación rápida'), findsOneWidget);
    expect(find.text('Pedir ayuda'), findsOneWidget);
    expect(find.text('Ofrecer un favor'), findsOneWidget);
    expect(find.text('Compartir un aviso'), findsOneWidget);

    await tester.tap(find.text('Ofrecer un favor'));
    await tester.pumpAndSettle();
    expect(find.text('Publicación rápida'), findsNothing);
    expect(find.text('Elegiste: Ofrecer un favor'), findsOneWidget);
    expect(find.text('Resumen de tu barrio'), findsOneWidget);
  });
}
