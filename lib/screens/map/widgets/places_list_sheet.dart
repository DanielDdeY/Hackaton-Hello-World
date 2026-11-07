import 'package:flutter/material.dart';

import '../models/map_place.dart';

/// Muestra una lista deslizable con los sitios visibles en el mapa.
///
/// Al pulsar uno se cierra el sheet y se llama a [onPlaceSelected] para que la
/// pantalla centre el mapa y abra su ficha.
Future<void> showPlacesListSheet(
  BuildContext context, {
  required List<MapPlace> places,
  required ValueChanged<MapPlace> onPlaceSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sitios en el mapa',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${places.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: places.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No hay sitios que coincidan con los filtros.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: places.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = places[index];
                          return _PlaceTile(
                            place: place,
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              onPlaceSelected(place);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});

  final MapPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = place.isBusiness
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.12),
        child: Icon(
          place.isBusiness ? Icons.storefront_rounded : Icons.bookmark_rounded,
          color: accent,
        ),
      ),
      title: Text(
        place.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        place.address.isEmpty
            ? place.category
            : '${place.category} · ${place.address}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: place.rating == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 2),
                Text(
                  place.rating!.toStringAsFixed(1),
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
    );
  }
}
