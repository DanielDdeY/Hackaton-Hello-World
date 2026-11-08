import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/entities/item_mascota.dart';
import '../../domain/entities/mascota.dart';

/// Hoja modal con la coleccion de accesorios de la mascota.
class ColeccionItemsSheet extends StatelessWidget {
  const ColeccionItemsSheet({
    super.key,
    required this.mascota,
    required this.onEquipar,
  });

  final Mascota mascota;
  final ValueChanged<String?> onEquipar;

  Color _colorRareza(RarezaItem rareza) {
    return switch (rareza) {
      RarezaItem.comun => const Color(0xFF6C757D),
      RarezaItem.raro => const Color(0xFF0077B6),
      RarezaItem.legendario => const Color(0xFFE76F51),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final desbloqueadosCount = ItemMascota.catalogoOficial
        .where((item) => mascota.tieneItem(item.id))
        .length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de arrastre superior
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Titulo y contador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Colección de Objetos',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$desbloqueadosCount de ${ItemMascota.catalogoOficial.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista cuadriculada de articulos
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: ItemMascota.catalogoOficial.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final item = ItemMascota.catalogoOficial[index];
                final tiene = mascota.tieneItem(item.id);
                final equipado = mascota.itemEquipadoId == item.id;
                final colorRareza = _colorRareza(item.rareza);

                return Container(
                  decoration: BoxDecoration(
                    color: tiene ? Colors.white : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: equipado
                          ? const Color(0xFF006D77)
                          : (tiene ? Colors.grey[300]! : Colors.grey[200]!),
                      width: equipado ? 2.0 : 1.0,
                    ),
                    boxShadow: equipado
                        ? const [
                            BoxShadow(
                              color: Color(0x22006D77),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge de rareza
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorRareza.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.rareza.etiqueta,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorRareza,
                            ),
                          ),
                        ),
                      ),

                      // Vista previa del item
                      SizedBox(
                        height: 64,
                        child: tiene
                            ? (item.assetPath.endsWith('.svg')
                                ? SvgPicture.asset(
                                    item.assetPath,
                                    fit: BoxFit.contain,
                                  )
                                : Image.asset(
                                    item.assetPath,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.check_circle_outline,
                                      size: 40,
                                      color: Color(0xFF006D77),
                                    ),
                                  ))
                            : ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.srcIn,
                                ),
                                child: const Icon(Icons.lock_outline, size: 36),
                              ),
                      ),

                      // Nombre del item
                      Text(
                        tiene ? item.nombre : 'Por descubrir',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: tiene ? FontWeight.w600 : FontWeight.normal,
                          color: tiene ? Colors.black87 : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Boton de accion (Equipar / Quitar / Bloqueado)
                      if (tiene)
                        SizedBox(
                          width: double.infinity,
                          height: 30,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: equipado ? const Color(0xFF006D77) : Colors.transparent,
                              side: const BorderSide(color: Color(0xFF006D77)),
                            ),
                            onPressed: () => onEquipar(equipado ? null : item.id),
                            child: Text(
                              equipado ? 'Quitar' : 'Equipar',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: equipado ? Colors.white : const Color(0xFF006D77),
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          '${(item.probabilidad * 100).toInt()}% prob.',
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
