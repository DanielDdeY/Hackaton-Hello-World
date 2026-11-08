import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local del checklist y foto verificada de la mochila de emergencia.
///
/// Guarda en `shared_preferences` para que funcione sin internet.
abstract final class BackpackChecklistStore {
  static const _key = 'mochila_checklist_v1';
  static const _photoKey = 'mochila_foto_verificada_v1';

  /// Items por defecto; los elementos guardados previamente se conservan.
  static const defaultItems = <String>[
    'Agua',
    'Botiquín',
    'Linterna',
    'Radio',
    'Alimentos no perecibles',
    'Pilas de repuesto',
    'Silbato',
    'Artículos de higiene',
    'Documentos importantes',
    'Dinero en efectivo',
  ];

  /// Carga el estado guardado o los items por defecto sin marcar.
  static Future<Map<String, bool>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved == null) {
      return {for (final item in defaultItems) item: false};
    }
    return {for (final item in defaultItems) item: saved.contains(item)};
  }

  /// Guarda los ítems marcados.
  static Future<void> save(Map<String, bool> state) async {
    final prefs = await SharedPreferences.getInstance();
    final checked = state.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    await prefs.setStringList(_key, checked);
  }

  /// Carga la ruta/identificador de la foto tomada para verificar la mochila.
  static Future<String?> loadPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_photoKey);
    return path != null && path.trim().isNotEmpty ? path : null;
  }

  /// Guarda la ruta/identificador de la foto tomada para verificar la mochila.
  static Future<void> savePhotoPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.trim().isEmpty) {
      await prefs.remove(_photoKey);
    } else {
      await prefs.setString(_photoKey, path.trim());
    }
  }
}
