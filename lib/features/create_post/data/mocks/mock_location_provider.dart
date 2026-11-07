import '../../domain/services/location_provider.dart';

final class MockLocationProvider implements LocationProvider {
  const MockLocationProvider({this.shouldFail = false});

  final bool shouldFail;

  @override
  Future<String> getCurrentAddress() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (shouldFail) throw const LocationUnavailableException();

    return 'Av. Principal 123 - GPS Activo';
  }
}
