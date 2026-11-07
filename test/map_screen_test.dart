import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:hackaton_hello_world/screens/map/data/map_location_provider.dart';
import 'package:hackaton_hello_world/screens/map/data/map_places_repository.dart';
import 'package:hackaton_hello_world/screens/map/map_screen.dart';
import 'package:hackaton_hello_world/screens/map/models/map_place.dart';
import 'package:hackaton_hello_world/screens/map/widgets/location_permission_view.dart';

void main() {
  const userLocation = LatLng(40.4168, -3.7038);

  // A ~300 m del usuario.
  final nearPlace = MapPlace(
    id: 'near',
    name: 'Café Central',
    category: 'Cafetería',
    latitude: 40.4147,
    longitude: -3.7003,
  );

  // A ~20 km del usuario: debe quedarse fuera del radio.
  final farPlace = MapPlace(
    id: 'far',
    name: 'Lejano',
    category: 'Tienda',
    latitude: 40.6,
    longitude: -3.7038,
  );

  testWidgets('con ubicación muestra el mapa y filtra fuera de 1.8 km', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          repository: _FakeRepository([nearPlace, farPlace]),
          locationProvider: _FakeLocationProvider([
            const LocationResult.success(userLocation),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(LocationPermissionView), findsNothing);
    expect(find.byType(TextField), findsOneWidget);

    // Marcador del usuario + sitio cercano; el lejano queda fuera.
    final markers = tester
        .widget<MarkerLayer>(find.byType(MarkerLayer))
        .markers;
    expect(markers, hasLength(2));
    expect(markers.any((marker) => marker.point == userLocation), isTrue);
  });

  testWidgets('bloquea el mapa sin permiso y lo desbloquea al concederlo', (
    tester,
  ) async {
    final provider = _FakeLocationProvider([
      const LocationResult.failure(LocationFailure.permissionDenied),
      const LocationResult.success(userLocation),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          repository: _FakeRepository(const []),
          locationProvider: provider,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LocationPermissionView), findsOneWidget);
    expect(find.text('Permitir ubicación'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);

    await tester.tap(find.text('Permitir ubicación'));
    await tester.pumpAndSettle();

    expect(provider.calls, 2);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(LocationPermissionView), findsNothing);
  });

  testWidgets('el FAB centra el mapa en la ubicación del usuario', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          repository: _FakeRepository(const []),
          locationProvider: _FakeLocationProvider([
            const LocationResult.success(userLocation),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fab = find.byTooltip('Centrar en mi ubicación');
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.pumpAndSettle();
  });

  testWidgets('avisa de la última ubicación y lo quita al recibir una '
      'posición en vivo', (tester) async {
    final updates = StreamController<LocationResult>();
    addTearDown(updates.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          repository: _FakeRepository(const []),
          locationProvider: _FakeLocationProvider(
            [
              const LocationResult.success(userLocation, isLastKnown: true),
            ],
            watchStream: updates.stream,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Arranca con la última ubicación guardada: el mapa se ve y se avisa.
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      find.text('Mostrando tu última ubicación conocida'),
      findsOneWidget,
    );

    // Llega una posición en vivo: el aviso desaparece.
    updates.add(const LocationResult.success(userLocation));
    await tester.pumpAndSettle();
    expect(
      find.text('Mostrando tu última ubicación conocida'),
      findsNothing,
    );
  });

  testWidgets('si el GPS se corta, el mapa sigue con el último punto', (
    tester,
  ) async {
    final updates = StreamController<LocationResult>();
    addTearDown(updates.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          repository: _FakeRepository(const []),
          locationProvider: _FakeLocationProvider(
            [const LocationResult.success(userLocation)],
            watchStream: updates.stream,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      find.text('Mostrando tu última ubicación conocida'),
      findsNothing,
    );

    // El GPS se apaga: se queda en el último punto y aparece el aviso.
    updates.add(
      const LocationResult.success(userLocation, isLastKnown: true),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      find.text('Mostrando tu última ubicación conocida'),
      findsOneWidget,
    );
  });
}

class _FakeLocationProvider implements MapLocationProvider {
  _FakeLocationProvider(this._results, {this.watchStream});

  final List<LocationResult> _results;
  final Stream<LocationResult>? watchStream;
  int calls = 0;

  @override
  Future<LocationResult> currentLocation() async {
    final index = calls < _results.length ? calls : _results.length - 1;
    calls++;
    return _results[index];
  }

  @override
  Stream<LocationResult> watch() =>
      watchStream ?? const Stream<LocationResult>.empty();
}

class _FakeRepository implements MapPlacesRepository {
  _FakeRepository(this._places);

  final List<MapPlace> _places;

  @override
  Stream<List<MapPlace>> watchPlaces() => Stream.value(_places);
}
