import 'package:flutter/material.dart';

/// Métricas de participación y actividad comunitaria en el barrio.
class PerfilActividad extends StatelessWidget {
  const PerfilActividad({
    super.key,
    required this.favoresCompletados,
    required this.eventosAsistidos,
    required this.reconocimientos,
    required this.rachaSemanal,
  });

  final int favoresCompletados;
  final int eventosAsistidos;
  final int reconocimientos;
  final int rachaSemanal;

  Widget _tarjetaDato({
    required BuildContext context,
    required IconData icono,
    required Color color,
    required String valor,
    required String titulo,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insights_outlined, size: 20, color: Color(0xFF006D77)),
            const SizedBox(width: 8),
            Text(
              'Tu actividad en el barrio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _tarjetaDato(
                context: context,
                icono: Icons.handshake_outlined,
                color: const Color(0xFF0284C7),
                valor: '$favoresCompletados',
                titulo: 'Favores listos',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tarjetaDato(
                context: context,
                icono: Icons.event_available_outlined,
                color: const Color(0xFF16A34A),
                valor: '$eventosAsistidos',
                titulo: 'Eventos asistidos',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _tarjetaDato(
                context: context,
                icono: Icons.thumb_up_alt_outlined,
                color: const Color(0xFF8B5CF6),
                valor: '$reconocimientos',
                titulo: 'Reconocimientos',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tarjetaDato(
                context: context,
                icono: Icons.local_fire_department_outlined,
                color: const Color(0xFFEA580C),
                valor: '$rachaSemanal sem',
                titulo: 'Racha activa',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

