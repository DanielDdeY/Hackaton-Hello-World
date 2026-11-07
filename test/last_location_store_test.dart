import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hackaton_hello_world/screens/map/data/last_location_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('guarda y recupera la última ubicación', () async {
    SharedPreferences.setMockInitialValues({});

    final store = await SharedPreferencesLastLocationStore.create();
    expect(await store.read(), isNull);

    await store.write(const LatLng(40.4168, -3.7038));

    // Simula un reinicio: una instancia nueva sobre las mismas preferencias.
    final reopened = await SharedPreferencesLastLocationStore.create();
    final stored = await reopened.read();
    expect(stored, isNotNull);
    expect(stored!.latitude, closeTo(40.4168, 0.000001));
    expect(stored.longitude, closeTo(-3.7038, 0.000001));
  });

  test('el almacén en memoria sirve de respaldo', () async {
    final store = InMemoryLastLocationStore();
    expect(await store.read(), isNull);

    await store.write(const LatLng(40.0, -3.0));
    final stored = await store.read();
    expect(stored!.latitude, 40.0);
    expect(stored.longitude, -3.0);
  });
}
