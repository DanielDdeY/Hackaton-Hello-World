import 'package:flutter/material.dart';

import '../../../economia/domain/entities/nivel_xp.dart';

/// Cabecera visual del perfil con avatar, nombre, ubicación y barra de progresión de nivel.
class PerfilCabecera extends StatelessWidget {
  const PerfilCabecera({
    super.key,
    required this.nombre,
    required this.iniciales,
    required this.distrito,
    this.provincia,
    required this.xp,
    this.foto = false,
  });

  final String nombre;
  final String iniciales;
  final String distrito;
  final String? provincia;
  final int xp;
  final bool foto;

  String _tituloNivel(int nivel) {
    return switch (nivel) {
      0 => 'Vecino principiante',
      1 => 'Vecino colaborador',
      2 => 'Vecino guardián',
      3 => 'Vecino protector',
      4 => 'Líder comunitario',
      _ => 'Héroe vecinal',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nivel = NivelXp.calcularNivel(xp);
    final progreso = NivelXp.progresoNivel(xp);
    final ganadoNivel = NivelXp.xpEnNivelActual(xp);
    final reqNivel = NivelXp.xpParaSiguienteNivel(nivel);
    final faltante = NivelXp.xpRestanteParaSiguienteNivel(xp);

    final ubicacion = [
      if (distrito.isNotEmpty) distrito else 'Ate',
      if (provincia != null && provincia!.isNotEmpty && provincia != distrito)
        provincia!,
    ].join(', ');

    return Column(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: const Color(0xFFE0F2F1),
          child: Text(
            iniciales.isEmpty ? 'V' : iniciales,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF006D77),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          nombre.isEmpty ? 'Vecino' : nombre,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF5C5C5C)),
            const SizedBox(width: 4),
            Text(
              ubicacion,
              style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5C5C5C)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF006D77).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF006D77).withOpacity(0.2)),
          ),
          child: Text(
            'Nivel $nivel · ${_tituloNivel(nivel)}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: const Color(0xFF006D77),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          color: const Color(0xFFF9FAFB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso de nivel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$ganadoNivel / $reqNivel XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5C5C5C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006D77)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Faltan $faltante XP para el Nivel ${nivel + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

