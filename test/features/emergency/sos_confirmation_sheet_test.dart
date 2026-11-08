import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/emergency/presentation/sos_confirmation_sheet.dart';

void main() {
  testWidgets('solo habilita Activar SOS al marcar la casilla', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SosConfirmationSheet())),
    );

    FilledButton button() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Activar SOS'),
    );

    expect(find.textContaining('bajo tu responsabilidad'), findsOneWidget);
    expect(button().onPressed, isNull);

    await tester.tap(find.text('Entiendo y asumo la responsabilidad'));
    await tester.pumpAndSettle();

    expect(button().onPressed, isNotNull);
  });
}
