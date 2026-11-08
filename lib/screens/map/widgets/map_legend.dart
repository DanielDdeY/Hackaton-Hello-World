import 'package:flutter/material.dart';

import '../../../features/emergency/domain/emergency_type_labels.dart';
import '../../../features/emergency/presentation/emergency_type_icons.dart';
import '../utils/map_geo.dart';

/// Leyenda colapsable del mapa: tipos de alerta activos y radios visibles.
class MapLegend extends StatefulWidget {
  const MapLegend({super.key, required this.alertTypes});

  final List<String> alertTypes;

  @override
  State<MapLegend> createState() => _MapLegendState();
}

class _MapLegendState extends State<MapLegend> {
  bool _expanded = false;

  List<String> get _uniqueTypes {
    final labels = <String>{};
    return [
      for (final type in widget.alertTypes)
        if (labels.add(emergencyTypeLabel(type))) type,
    ];
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(_expanded ? 16 : 999),
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggle,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 8, _expanded ? 16 : 12, 8),
            child: _expanded
                ? _expandedContent(theme)
                : _collapsedContent(theme),
          ),
        ),
      ),
    );
  }

  Widget _collapsedContent(ThemeData theme) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.legend_toggle_rounded,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 6),
      Text(
        'Leyenda',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 4),
      Icon(
        Icons.expand_more_rounded,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ],
  );

  Widget _expandedContent(ThemeData theme) {
    final types = _uniqueTypes;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260, maxHeight: 320),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.legend_toggle_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Leyenda',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_less_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Tipos de alerta',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (types.isEmpty)
              Text(
                'Sin alertas SOS activas',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final type in types)
                _LegendRow(
                  icon: emergencyTypeIcon(type),
                  label: emergencyTypeLabel(type),
                ),
            const SizedBox(height: 10),
            Text(
              'Círculos',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            _LegendRow(
              icon: Icons.circle,
              iconColor: theme.colorScheme.primary.withValues(alpha: 0.55),
              label:
                  'Tu zona (${(kMapRadiusMeters / 1000).toStringAsFixed(1)} km)',
            ),
            _LegendRow(
              icon: Icons.circle,
              iconColor: const Color(0xffb71c1c),
              label: 'Alerta SOS (200 m)',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.icon, required this.label, this.iconColor});

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xffb71c1c)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
