class SosSmsContact {
  const SosSmsContact({required this.name, required this.phoneNumber});

  final String name;
  final String phoneNumber;

  static String? normalizePhoneNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !RegExp(r'^[+0-9\s().-]+$').hasMatch(trimmed)) {
      return null;
    }

    final normalized = trimmed.replaceAll(RegExp(r'[\s().-]'), '');
    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(normalized)) return null;
    return normalized;
  }

  factory SosSmsContact.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final phoneNumber = json['phoneNumber'];
    if (name is! String || phoneNumber is! String) {
      throw const FormatException('Contacto SOS inválido.');
    }
    final normalized = normalizePhoneNumber(phoneNumber);
    if (name.trim().isEmpty || normalized == null) {
      throw const FormatException('Contacto SOS inválido.');
    }
    return SosSmsContact(name: name.trim(), phoneNumber: normalized);
  }

  Map<String, String> toJson() => {
    'name': name,
    'phoneNumber': phoneNumber,
  };
}
