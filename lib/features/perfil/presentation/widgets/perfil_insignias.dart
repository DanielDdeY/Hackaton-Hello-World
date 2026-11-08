import 'package:flutter/material.dart';

import 'catalogo_insignias.dart';

/// Sección de insignias y logros comunitarios con modal explicativo.
class PerfilInsignias extends StatelessWidget {
  const PerfilInsignias({super.key, required this.insignias});

  final List<String> insignias;

  void _mostrarDetalleInsignia(BuildContext context, InfoInsignia info) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: info.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(info.icono, color: info.color, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  info.nombre,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  info.descripcion,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006D77),
                  ),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listaUnica = insignias.toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.military_tech_outlined, size: 20, color: Color(0xFF006D77)),
            const SizedBox(width: 8),
            Text(
              'Insignias y logros',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (listaUnica.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: Color(0xFF6B7280)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aún no tienes insignias. ¡Prepara tu mochila de emergencia o ayuda a un vecino para conseguirlas!',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slug in listaUnica) ...[
                () {
                  final info = CatalogoInsignias.resolver(slug);
                  return ActionChip(
                    avatar: Icon(info.icono, size: 18, color: info.color),
                    label: Text(info.nombre),
                    backgroundColor: info.color.withOpacity(0.08),
                    side: BorderSide(color: info.color.withOpacity(0.3)),
                    onPressed: () => _mostrarDetalleInsignia(context, info),
                  );
                }(),
              ],
            ],
          ),
      ],
    );
  }
}

