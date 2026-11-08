import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/community/presentation/community_sos_section.dart';
import 'package:latlong2/latlong.dart';

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
    expect(find.text('SOS · ACCIDENTE'), findsOneWidget);
    expect(find.text('1 activa'), findsOneWidget);
    expect(find.text('Choque en la avenida'), findsOneWidget);
    expect(
      find.text('Un carro chocó con el bus de la ruta 47.'),
      findsOneWidget,
    );
  });

  testWidgets('traduce el tipo robbery a ROBO', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommunitySosSection(
            alerts: Stream.value([
              {
                'alertId': 'sos-2',
                'emergencyType': 'robbery',
                'title': 'Robo en la esquina',
                'status': 'active',
              },
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SOS · ROBO'), findsOneWidget);
  });

  testWidgets('abre el mapa centrado en la alerta desde la tarjeta', (
    tester,
  ) async {
    LatLng? focused;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommunitySosSection(
            alerts: Stream.value([
              {
                'alertId': 'sos-3',
                'emergencyType': 'robbery',
                'title': 'Robo en la esquina',
                'location': const GeoPoint(-12.1, -77.0),
                'status': 'active',
              },
            ]),
            onOpenMap: (location) => focused = location,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver en mapa'));
    await tester.pumpAndSettle();

    expect(focused, const LatLng(-12.1, -77.0));
  });
}
