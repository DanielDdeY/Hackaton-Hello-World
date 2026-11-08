import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/sos_sms_contact.dart';

abstract interface class SosSmsContactStore {
  Future<List<SosSmsContact>> readContacts();
  Future<void> saveContacts(List<SosSmsContact> contacts);
}

final class SecureSosSmsContactStore implements SosSmsContactStore {
  SecureSosSmsContactStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'trusted_sos_sms_contacts_v1';
  final FlutterSecureStorage _storage;

  @override
  Future<List<SosSmsContact>> readContacts() async {
    final encoded = await _storage.read(key: _storageKey);
    if (encoded == null || encoded.isEmpty) return const [];

    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      throw const FormatException('No se pudieron leer los contactos SOS.');
    }
    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('No se pudieron leer los contactos SOS.');
      }
      return SosSmsContact.fromJson(item);
    }).toList(growable: false);
  }

  @override
  Future<void> saveContacts(List<SosSmsContact> contacts) async {
    final numbers = <String>{};
    for (final contact in contacts) {
      final normalized = SosSmsContact.normalizePhoneNumber(
        contact.phoneNumber,
      );
      if (contact.name.trim().isEmpty ||
          normalized == null ||
          !numbers.add(normalized)) {
        throw ArgumentError('La lista de contactos SOS no es válida.');
      }
    }
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(contacts.map((contact) => contact.toJson()).toList()),
    );
  }
}
