import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/community/presentation/community_sos_section.dart';

void main() {
  testWidgets('shows SOS details in the community section', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommunitySosSection(
            alerts: Stream.value([
              {
                'alertId': 'sos-1',
                'emergencyType': 'accident',
                'title': 'Choque en la avenida',
                'description': 'Un carro chocó con el bus de la ruta 47.',
                'status': 'active',
              },
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alertas SOS cercanas'), findsOneWidget);
    expect(find.text('SOS · ACCIDENT'), findsOneWidget);
    expect(find.text('Choque en la avenida'), findsOneWidget);
    expect(
      find.text('Un carro chocó con el bus de la ruta 47.'),
      findsOneWidget,
    );
  });
}
