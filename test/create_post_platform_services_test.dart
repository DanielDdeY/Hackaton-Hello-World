import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart' show Placemark;
import 'package:hackaton_hello_world/core/errors/photo_picker_failure.dart';
import 'package:hackaton_hello_world/core/widgets/form_footer_buttons.dart';
import 'package:hackaton_hello_world/features/create_post/data/mocks/mock_photo_picker.dart';
import 'package:hackaton_hello_world/features/create_post/data/services/device_location_provider.dart';
import 'package:hackaton_hello_world/features/create_post/data/services/firebase_auth_gateway.dart';
import 'package:hackaton_hello_world/features/create_post/data/services/geocoding_address_resolver.dart';
import 'package:hackaton_hello_world/features/create_post/data/services/image_picker_photo_picker.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/auth_gateway.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/location_provider.dart';
import 'package:hackaton_hello_world/features/create_post/presentation/auth/ensure_post_author.dart';
import 'package:hackaton_hello_world/features/create_post/presentation/forms/emergency/emergency_form_controller.dart';
import 'package:hackaton_hello_world/screens/map/data/map_location_provider.dart'
    as map;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class _FakeAuth extends Fake implements FirebaseAuth {
  var calls = 0;
  @override
  User? currentUser;
  Completer<UserCredential> result = Completer<UserCredential>();

  @override
  Future<UserCredential> signInAnonymously() {
    calls++;
    return result.future;
  }
}

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'anonymous-test-uid';
}

class _FakeCredential extends Fake implements UserCredential {
  _FakeCredential(this.user);

  @override
  final User user;
}

class _FixedMapProvider extends Fake implements map.MapLocationProvider {
  _FixedMapProvider(this.result);

  final map.LocationResult result;

  @override
  Future<map.LocationResult> currentLocation() async => result;
}

class _FakePicker extends Fake implements ImagePicker {
  bool denyCamera = false;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    expect(
      (maxWidth, maxHeight, imageQuality, requestFullMetadata),
      (1600.0, 1600.0, 80, false),
    );
    if (source == ImageSource.gallery) return null;
    if (denyCamera) throw PlatformException(code: 'camera_access_denied');
    return XFile('photo.jpg');
  }
}

void main() {
  testWidgets('Publicar disables itself during auth and can retry a failure', (
    tester,
  ) async {
    final auth = _FakeAuth();
    final gateway = FirebaseAuthGateway(auth);
    var accepted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<AuthGateway?>.value(
          value: gateway,
          child: Scaffold(
            body: Builder(
              builder: (context) => FormFooterButtons(
                onPublish: () async {
                  accepted = await ensurePostAuthor(context);
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Publicar'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    auth.result.completeError(
      FirebaseAuthException(code: 'network-request-failed'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Sin conexión. Conéctate y vuelve a tocar Publicar.'),
      findsOneWidget,
    );
    expect(accepted, isFalse);

    auth.result = Completer<UserCredential>();
    await tester.tap(find.text('Publicar'));
    auth.result.complete(_FakeCredential(_FakeUser()));
    await tester.pumpAndSettle();
    expect(accepted, isTrue);
    expect(auth.calls, 2);
  });

  test(
    'anonymous sign-in shares an attempt, maps failures and allows retry',
    () async {
      final auth = _FakeAuth();
      final gateway = FirebaseAuthGateway(auth);
      final first = gateway.ensureSignedIn();
      final second = gateway.ensureSignedIn();
      final denied = throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.reason,
          'reason',
          AuthFailureReason.anonymousDisabled,
        ),
      );
      final checks = [expectLater(first, denied), expectLater(second, denied)];
      auth.result.completeError(
        FirebaseAuthException(code: 'operation-not-allowed'),
      );
      await Future.wait(checks);
      expect(auth.calls, 1);

      auth.result = Completer<UserCredential>();
      final retry = gateway.ensureSignedIn();
      final user = _FakeUser();
      auth.currentUser = user;
      auth.result.complete(_FakeCredential(user));
      expect(await retry, user.uid);
      expect(await gateway.ensureSignedIn(), user.uid);
      expect(auth.calls, 2);
    },
  );

  test(
    'the location adapter keeps cached provenance and resolves an address',
    () async {
      final provider = DeviceLocationProvider(
        mapProvider: _FixedMapProvider(
          const map.LocationResult.success(
            LatLng(-12.0464, -77.0428),
            isLastKnown: true,
          ),
        ),
        addressResolver: GeocodingAddressResolver(
          lookup: (latitude, longitude) async {
            expect((latitude, longitude), (-12.0464, -77.0428));
            return const [
              Placemark(
                thoroughfare: 'Av. Lima',
                subThoroughfare: '123',
                subLocality: 'Centro',
              ),
            ];
          },
        ),
      );
      final location = await provider.getCurrentLocation();
      expect(location.isLastKnown, isTrue);
      expect(await provider.resolveAddress(location), 'Av. Lima 123, Centro');
    },
  );

  test('maps disabled GPS to an explicit error', () async {
    final provider = DeviceLocationProvider(
      mapProvider: _FixedMapProvider(
        const map.LocationResult.failure(map.LocationFailure.serviceDisabled),
      ),
      addressResolver: const GeocodingAddressResolver(),
    );
    await expectLater(
      provider.getCurrentLocation(),
      throwsA(
        isA<LocationUnavailableException>().having(
          (failure) => failure.reason,
          'reason',
          LocationUnavailableReason.serviceDisabled,
        ),
      ),
    );
  });

  testWidgets(
    'coordinates make the emergency valid before geocoding finishes',
    (tester) async {
      final lookup = Completer<List<Placemark>>();
      final provider = DeviceLocationProvider(
        mapProvider: _FixedMapProvider(
          const map.LocationResult.success(LatLng(-12.0464, -77.0428)),
        ),
        addressResolver: GeocodingAddressResolver(
          lookup: (_, _) => lookup.future,
        ),
      );
      final controller = EmergencyFormController(
        locationProvider: provider,
        photoPicker: const MockPhotoPicker(),
      );
      addTearDown(controller.dispose);
      await tester.pump();
      expect(
        controller.streetAddressController.text,
        'Cerca de -12.0464, -77.0428',
      );
      expect(controller.data.isValid, isTrue);

      controller.streetAddressController.text = 'Mi dirección manual';
      controller.markAddressEdited('Mi dirección manual');
      lookup.complete(const [Placemark(street: 'Av. Lima 123')]);
      await tester.pump();
      expect(controller.streetAddressController.text, 'Mi dirección manual');
    },
  );

  testWidgets('returns the coordinates after five seconds without an address', (
    tester,
  ) async {
    final provider = DeviceLocationProvider(
      mapProvider: _FixedMapProvider(
        const map.LocationResult.success(LatLng(-12.0464, -77.0428)),
      ),
      addressResolver: GeocodingAddressResolver(
        lookup: (_, _) => Completer<List<Placemark>>().future,
      ),
    );
    final result = provider.getCurrentAddress();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(await result, 'Cerca de -12.0464, -77.0428');
  });

  test(
    'real picker requests smaller photos and preserves cancellation',
    () async {
      final platform = _FakePicker();
      final picker = ImagePickerPhotoPicker(platform);
      expect(await picker.pickFromCamera(), 'photo.jpg');
      expect(await picker.pickFromGallery(), isNull);
      platform.denyCamera = true;
      await expectLater(
        picker.pickFromCamera(),
        throwsA(
          isA<PhotoPickerFailure>().having(
            (failure) => failure.reason,
            'reason',
            PhotoPickerFailureReason.cameraDenied,
          ),
        ),
      );
    },
  );
}
