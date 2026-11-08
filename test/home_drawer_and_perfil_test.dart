import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('drawer muestra opciones esenciales y navega a Mi perfil y confirma cierre de sesión', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'tutorial_inicio_v1_visto': true,
      'vecino_departamento': 'Lima',
      'vecino_provincia': 'Lima',
      'vecino_distrito': 'Ate',
      'vecino_nombre': 'Carlos Mendoza',
      'vecino_telefono': '987654321',
      'vecino_xp': 150,
      'vecino_fichas': 45,
    });

    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    void openDrawer() {
      final scaffold = tester.state<ScaffoldState>(
        find.byWidgetPredicate((w) => w is Scaffold && w.drawer != null),
      );
      scaffold.openDrawer();
    }

    // Abrir menú hamburguesa
    openDrawer();
    await tester.pumpAndSettle();

    // Verificar enlaces organizados del nuevo menú
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Mi mascota'), findsOneWidget);
    expect(find.text('Contactos SOS por SMS'), findsOneWidget);
    expect(find.text('Ayuda y prevención'), findsOneWidget);
    expect(find.text('Aviso de responsabilidad SOS'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);

    // Verificar que los elementos redundantes fueron retirados del drawer
    expect(find.text('Estadísticas y Nivel'), findsNothing);
    expect(find.text('Insignias comunitarias'), findsNothing);

    // Tocar 'Mi perfil'
    await tester.tap(find.text('Mi perfil'));
    await tester.pumpAndSettle();

    // Verificar elementos de la nueva página de perfil
    expect(find.text('Progreso de nivel'), findsOneWidget);
    expect(find.text('XP del mes'), findsOneWidget);
    expect(find.text('Fichas'), findsOneWidget);
    expect(find.text('Mi Mascota Vecinal'), findsOneWidget);
    expect(find.text('Mochila de Emergencia'), findsOneWidget);
    expect(find.text('Insignias y logros'), findsOneWidget);
    expect(find.text('Tu actividad en el barrio'), findsOneWidget);
    expect(find.text('Información del vecino'), findsOneWidget);
    expect(find.text('Contactos SOS'), findsOneWidget);
    expect(find.text('Editar datos'), findsOneWidget);

    // Regresar al inicio
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Abrir drawer nuevamente para probar diálogo de cerrar sesión
    openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    // Diálogo de confirmación
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    // Cancelar no cierra sesión
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('AYNI VECI'), findsOneWidget);

    // Abrir drawer y confirmar cierre de sesión
    openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Continuar con celular'), findsOneWidget);
  });
}

