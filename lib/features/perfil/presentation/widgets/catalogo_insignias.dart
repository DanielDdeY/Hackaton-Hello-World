import 'package:flutter/material.dart';

/// Información descriptiva y estética de una insignia vecinal.
class InfoInsignia {
  const InfoInsignia({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.color,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final IconData icono;
  final Color color;
}

/// Catálogo centralizado de insignias comunitarias con soporte para slugs arbitrarios.
class CatalogoInsignias {
  const CatalogoInsignias._();

  static const Map<String, InfoInsignia> _conocidas = {
    'vecino-preparado': InfoInsignia(
      id: 'vecino-preparado',
      nombre: 'Vecino preparado',
      descripcion: 'Completó y verificó su mochila de emergencia con los 10 elementos esenciales.',
      icono: Icons.backpack_outlined,
      color: Color(0xFFD97706),
    ),
    'vecino-solidario': InfoInsignia(
      id: 'vecino-solidario',
      nombre: 'Vecino solidario',
      descripcion: 'Participó activamente ayudando a sus vecinos en situaciones comunitarias.',
      icono: Icons.volunteer_activism_outlined,
      color: Color(0xFF16A34A),
    ),
    'vecino-alerta': InfoInsignia(
      id: 'vecino-alerta',
      nombre: 'Vecino alerta',
      descripcion: 'Participó en simulacros y se mantiene activo en la red de prevención de desastres.',
      icono: Icons.notifications_active_outlined,
      color: Color(0xFFDC2626),
    ),
    'primer-favor': InfoInsignia(
      id: 'primer-favor',
      nombre: 'Primer favor',
      descripcion: 'Realizó su primera ayuda vecinal en AyniVeci.',
      icono: Icons.handshake_outlined,
      color: Color(0xFF0284C7),
    ),
  };

  /// Resuelve la insignia por id. Si no existe en el catálogo, genera una representación legible.
  static InfoInsignia resolver(String id) {
    final normalizado = id.trim().toLowerCase();
    final conocida = _conocidas[normalizado];
    if (conocida != null) return conocida;

    final nombreLegible = id
        .split(RegExp(r'[-_]'))
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join(' ');

    return InfoInsignia(
      id: id,
      nombre: nombreLegible.isEmpty ? 'Insignia vecinal' : nombreLegible,
      descripcion: 'Reconocimiento otorgado por participación comunitaria en el barrio.',
      icono: Icons.military_tech_outlined,
      color: const Color(0xFF006D77),
    );
  }
}

