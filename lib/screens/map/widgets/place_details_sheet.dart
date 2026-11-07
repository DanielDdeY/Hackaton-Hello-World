import 'package:flutter/material.dart';

import '../models/map_place.dart';

/// Muestra la ficha de un sitio en un bottom sheet.
///
/// [onFocus] se ejecuta después de cerrar el sheet para centrar el mapa en el
/// sitio seleccionado.
Future<void> showPlaceDetailsSheet(
  BuildContext context, {
  required MapPlace place,
  VoidCallback? onFocus,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final accent = place.isBusiness
          ? theme.colorScheme.primary
          : theme.colorScheme.tertiary;

      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    child: Icon(
                      place.isBusiness
                          ? Icons.storefront_rounded
                          : Icons.bookmark_rounded,
                      color: accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Tag(
                              icon: place.isBusiness
                                  ? Icons.storefront_rounded
                                  : Icons.bookmark_rounded,
                              label: place.kind.label,
                              color: accent,
                            ),
                            _Tag(
                              icon: Icons.category_outlined,
                              label: place.category,
                              color: theme.colorScheme.secondary,
                            ),
                            if (place.rating != null)
                              _Tag(
                                icon: Icons.star_rounded,
                                label: place.rating!.toStringAsFixed(1),
                                color: Colors.amber.shade700,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (place.address.isNotEmpty)
                _InfoRow(icon: Icons.place_outlined, text: place.address),
              if (place.savedBy != null && place.savedBy!.isNotEmpty)
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  text: 'Guardado por ${place.savedBy}',
                ),
              if (place.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  place.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onFocus?.call();
                  },
                  icon: const Icon(Icons.center_focus_strong_rounded),
                  label: const Text('Centrar en el mapa'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
