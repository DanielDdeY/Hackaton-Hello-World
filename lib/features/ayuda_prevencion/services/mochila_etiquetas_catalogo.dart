/// Catálogo semántico que asocia etiquetas en inglés producidas por modelos de visión
/// (como Google ML Kit Image Labeling) con los 10 elementos esenciales de la mochila.
class MochilaEtiquetasCatalogo {
  const MochilaEtiquetasCatalogo._();

  static const Map<String, List<String>> _mapeo = {
    'Agua': [
      'water',
      'bottle',
      'drink',
      'beverage',
      'plastic bottle',
      'liquid',
      'mineral water',
    ],
    'Botiquín': [
      'first aid',
      'medicine',
      'box',
      'medical equipment',
      'bandage',
      'pill',
      'pharmacy',
      'health care',
      'gauze',
      'medical kit',
    ],
    'Linterna': [
      'flashlight',
      'torch',
      'light',
      'lamp',
      'lantern',
      'lighting',
    ],
    'Radio': [
      'radio',
      'communication',
      'electronic device',
      'boombox',
      'transceiver',
      'audio equipment',
    ],
    'Alimentos no perecibles': [
      'food',
      'can',
      'tin',
      'packaged goods',
      'snack',
      'canned food',
      'convenience food',
      'ingredient',
    ],
    'Pilas de repuesto': [
      'battery',
      'cell',
      'electronic',
      'accumulator',
      'dry cell',
    ],
    'Silbato': [
      'whistle',
      'musical instrument',
      'tool',
      'brass instrument',
    ],
    'Artículos de higiene': [
      'soap',
      'toilet paper',
      'tissue',
      'cosmetics',
      'toiletries',
      'towel',
      'hygiene',
      'cleaner',
    ],
    'Documentos importantes': [
      'document',
      'paper',
      'passport',
      'book',
      'text',
      'envelope',
      'folder',
      'certificate',
    ],
    'Dinero en efectivo': [
      'cash',
      'money',
      'banknote',
      'coin',
      'wallet',
      'currency',
      'dollar',
      'bill',
    ],
  };

  /// Obtiene las palabras clave asociadas a un elemento de la mochila.
  static List<String> palabrasClave(String item) {
    return _mapeo[item] ?? const [];
  }

  /// Retorna la primera etiqueta detectada que coincide con las palabras clave esperadas,
  /// o `null` si ninguna coincide.
  static String? etiquetaCoincidente(String item, List<String> etiquetasDetectadas) {
    final esperadas = palabrasClave(item);
    for (final etiqueta in etiquetasDetectadas) {
      final normalizada = etiqueta.trim().toLowerCase();
      for (final clave in esperadas) {
        if (normalizada == clave ||
            normalizada.contains(clave) ||
            clave.contains(normalizada)) {
          return etiqueta;
        }
      }
    }
    return null;
  }

  /// Verifica si el conjunto de etiquetas detectadas contiene alguna compatible con el elemento.
  static bool coincideConItem(String item, List<String> etiquetasDetectadas) {
    return etiquetaCoincidente(item, etiquetasDetectadas) != null;
  }
}

