abstract interface class EconomyStore {
  String newOperationId();
  Object get serverTimestamp;
  Future<T> runTransaction<T>(Future<T> Function(EconomyTransaction tx) action);
}

abstract interface class EconomyTransaction {
  Future<Map<String, dynamic>?> get(String path);
  void create(String path, Map<String, dynamic> data);
  void update(String path, Map<String, dynamic> data);
}
