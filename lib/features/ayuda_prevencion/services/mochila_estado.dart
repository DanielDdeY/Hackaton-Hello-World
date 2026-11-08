import 'package:shared_preferences/shared_preferences.dart';

enum EstadoBonoMochila {
  noDisponible,
  disponible,
  reclamado,
}

/// Representa el estado de la mochila de emergencia y su elegibilidad de bono.
class MochilaEstado {
  const MochilaEstado({
    required this.items,
    required this.bonoReclamado,
    required this.totalItems,
    required this.checkedCount,
  });

  final Map<String, bool> items;
  final bool bonoReclamado;
  final int totalItems;
  final int checkedCount;

  bool get estaCompleta => checkedCount >= totalItems && totalItems > 0;

  EstadoBonoMochila get estadoBono {
    if (bonoReclamado) return EstadoBonoMochila.reclamado;
    if (estaCompleta) return EstadoBonoMochila.disponible;
    return EstadoBonoMochila.noDisponible;
  }
}

/// Marca local del bono de preparacion vecinal.
///
/// Las fichas y el XP los otorga unicamente el motor de economia
/// (`EconomySource.backpackVerified`); aqui solo se recuerda, sin red,
/// que el bono ya se reclamo para pintar el estado de la tarjeta.
abstract class MochilaVerificacion {
  static const String keyBonoReclamado = 'mochila_bono_reclamado_v1';
  static const String badgeVecinoPreparado = 'vecino-preparado';

  /// Identificador fijo de la fuente: garantiza un solo bono por usuario.
  static const String sourceId = 'mochila';

  /// Verifica si el usuario ya reclamo el bono unico.
  static Future<bool> isBonoReclamado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyBonoReclamado) ?? false;
  }

  /// Recuerda localmente el bono y la insignia. Llamar solo despues de que
  /// el motor de economia haya confirmado el otorgamiento.
  static Future<void> marcarReclamado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyBonoReclamado, true);
    final insignias = prefs.getStringList('vecino_insignias') ?? <String>[];
    if (!insignias.contains(badgeVecinoPreparado)) {
      await prefs.setStringList('vecino_insignias', [
        ...insignias,
        badgeVecinoPreparado,
      ]);
    }
  }
}

