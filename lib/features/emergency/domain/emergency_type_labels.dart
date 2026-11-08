const _labels = <String, String>{
  'robbery': 'ROBO',
  'accident': 'ACCIDENTE',
  'tragedy': 'TRAGEDIA',
  'health': 'SALUD',
  'fire': 'INCENDIO',
  'flood': 'INUNDACIÓN',
  'missingperson': 'PERSONA DESAPARECIDA',
  'other': 'OTRO',
  'emergency': 'EMERGENCIA',
  'emergencia': 'EMERGENCIA',
  'robo': 'ROBO',
  'accidente': 'ACCIDENTE',
  'tragedia': 'TRAGEDIA',
  'salud': 'SALUD',
  'incendio': 'INCENDIO',
  'inundacion': 'INUNDACIÓN',
  'personadesaparecida': 'PERSONA DESAPARECIDA',
  'otro': 'OTRO',
};

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ü', 'u')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Etiqueta legible en español para un tipo de emergencia guardado.
///
/// Acepta los nombres del enum (`robbery`, `accident`, ...), datos antiguos en
/// inglés o valores ya escritos en español.
String emergencyTypeLabel(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return 'EMERGENCIA';
  return _labels[_normalize(value)] ?? value.toUpperCase();
}
