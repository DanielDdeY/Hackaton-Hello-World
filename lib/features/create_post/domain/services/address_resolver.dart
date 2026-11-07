abstract interface class AddressResolver {
  Future<String?> resolve(double latitude, double longitude);
}
