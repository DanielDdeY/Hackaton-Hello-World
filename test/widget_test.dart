import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/auth_gateway.dart';
import 'package:hackaton_hello_world/main.dart';
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
}

void main() {
  testWidgets('muestra la bienvenida de Mi Barrio', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, vecino!'), findsOneWidget);
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
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('MI BARRIO'), findsOneWidget);
    expect(find.text('Carlos Mendoza'), findsOneWidget);
    expect(find.text('Servicios\nde oficios'), findsOneWidget);
  });

  testWidgets('la pestaña Ayuda abre la feature Ayuda y Prevención', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vecino_departamento': 'Lima',
      'vecino_provincia': 'Lima',
      'vecino_distrito': 'Miraflores',
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ayuda').last);
    await tester.pumpAndSettle();

    expect(find.text('Mochila de Emergencia'), findsOneWidget);
    expect(find.text('Prepárate para un simulacro'), findsOneWidget);
    expect(find.text('Encuentra orientación y apoyo'), findsNothing);
  });

  testWidgets('permite buscar ubicaciones y limpia niveles dependientes', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MyApp(authGateway: _TestAuthGateway(displayName: 'Ana García')),
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
