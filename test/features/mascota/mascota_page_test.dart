import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/mascota/data/repositories/local_mascota_repository.dart';
import 'package:hackaton_hello_world/features/mascota/presentation/pages/mascota_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('MascotaPage muestra el Cuy, saldo de fichas y abre coleccion', (tester) async {
    SharedPreferences.setMockInitialValues({
      'mascota_nombre_usr_test': 'Cuy Aventurero',
      'mascota_items_usr_test': '["mugiwara"]',
      'mascota_pity_usr_test': 5,
    });

    final prefs = await SharedPreferences.getInstance();
    final repo = LocalMascotaRepository(preferences: prefs);

    await tester.pumpWidget(
      MaterialApp(
        home: MascotaPage(
          uid: 'usr_test',
          mascotaRepository: repo,
          fichasActuales: 45,
          onFichasActualizadas: (_) {},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verifica nombre, fichas y contador de garantia
    expect(find.text('Cuy Aventurero'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    expect(find.text('5 de 20'), findsOneWidget);

    // Toca el boton Objetos para abrir la coleccion
    final objetosBtn = find.text('Objetos');
    expect(objetosBtn, findsOneWidget);
    await tester.tap(objetosBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verifica que se muestre el modal de coleccion y el contador 1 de 5
    expect(find.text('Colección de Objetos'), findsOneWidget);
    expect(find.text('1 de 5'), findsOneWidget);

    // Hace scroll en la cuadricula para ver el item desbloqueado al final
    await tester.scrollUntilVisible(
      find.text('Sombrero Mugiwara'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Sombrero Mugiwara'), findsOneWidget);
  });
}
