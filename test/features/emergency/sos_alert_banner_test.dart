import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/emergency/presentation/sos_alert_banner.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('no ocupa espacio cuando no hay alertas activas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SosAlertBanner(alerts: Stream.value(const []))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver'), findsNothing);
    expect(find.textContaining('SOS ·'), findsNothing);
  });

  testWidgets('muestra el aviso con la alerta más reciente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SosAlertBanner(
            alerts: Stream.value([
              {
                'alertId': 'sos-1',
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
    expect(find.text('Robo en la esquina'), findsOneWidget);
    expect(find.text('Ver'), findsOneWidget);
  });

  testWidgets('abre el mapa centrado en la alerta', (tester) async {
    LatLng? focused;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SosAlertBanner(
            alerts: Stream.value([
              {
                'alertId': 'sos-1',
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

    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver en el mapa'));
    await tester.pumpAndSettle();

    expect(focused, const LatLng(-12.1, -77.0));
  });

  testWidgets('la X oculta la alerta y una alerta nueva vuelve a mostrarse', (
    tester,
  ) async {
    final controller = StreamController<List<Map<String, dynamic>>>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SosAlertBanner(alerts: controller.stream)),
      ),
    );

    controller.add([
      {
        'alertId': 'sos-1',
        'emergencyType': 'robbery',
        'title': 'Robo en la esquina',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(1000),
        'status': 'active',
      },
    ]);
    await tester.pumpAndSettle();
    expect(find.text('SOS · ROBO'), findsOneWidget);

    await tester.tap(find.byTooltip('Ocultar aviso SOS'));
    await tester.pumpAndSettle();
    expect(find.text('SOS · ROBO'), findsNothing);
    expect(find.text('Ver'), findsNothing);

    controller.add([
      {
        'alertId': 'sos-2',
        'emergencyType': 'accident',
        'title': 'Choque en la avenida',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(2000),
        'status': 'active',
      },
    ]);
    await tester.pumpAndSettle();
    expect(find.text('SOS · ACCIDENTE'), findsOneWidget);
    expect(find.text('Choque en la avenida'), findsOneWidget);
  });
}
