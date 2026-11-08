import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/mascota/domain/entities/item_mascota.dart';
import 'package:hackaton_hello_world/features/mascota/presentation/widgets/cuy_stage.dart';

void main() {
  group('CuyStage - Acoplamiento y Escalado Relacional', () {
    testWidgets('Renderiza correctamente sin accesorios en diferentes tamaños', (tester) async {
      for (final size in [180.0, 280.0, 360.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CuyStage(size: size),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CuyStage), findsOneWidget);
        // Debe encontrarse la imagen base del Cuy y el fondo
        expect(find.byType(Image), findsNWidgets(2));
      }
    });

    testWidgets('Renderiza cada accesorio del catalogo sin desbordamiento', (tester) async {
      for (final item in ItemMascota.catalogoOficial) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CuyStage(
                size: 280,
                itemEquipado: item,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CuyStage), findsOneWidget);
      }
    });

    testWidgets('Reacciona al toque con animacion y texto ¡Cui cui!', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuyStage(size: 280),
          ),
        ),
      );
      await tester.pump();

      // Inicialmente no se muestra el globo de texto
      expect(find.text('¡Cui cui!'), findsNothing);

      // Toca el escenario del Cuy
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Aparece el mensaje interactivo
      expect(find.text('¡Cui cui!'), findsOneWidget);

      // Despues de 1 segundo se desvanece
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('¡Cui cui!'), findsNothing);
    });

    test('Compatibilidad de IDs de accesorios anteriores (piruleta y shrek)', () {
      final itemPiruleta = ItemMascota.porId('piruleta');
      expect(itemPiruleta, isNotNull);
      expect(itemPiruleta?.id, 'fiesta');
      expect(itemPiruleta?.nombre, 'Gorrito de Fiesta');

      final itemShrek = ItemMascota.porId('shrek');
      expect(itemShrek, isNotNull);
      expect(itemShrek?.id, 'vikingo');
      expect(itemShrek?.nombre, 'Casco Vikingo');
    });
  });
}

