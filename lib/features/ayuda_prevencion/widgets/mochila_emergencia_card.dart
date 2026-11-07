import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../services/backpack_checklist_store.dart';
import 'help_section_card.dart';

/// Tarjeta "Mochila de Emergencia" con checklist persistente (offline).
class MochilaEmergenciaCard extends StatefulWidget {
  const MochilaEmergenciaCard({super.key});

  @override
  State<MochilaEmergenciaCard> createState() => _MochilaEmergenciaCardState();
}

class _MochilaEmergenciaCardState extends State<MochilaEmergenciaCard> {
  late Map<String, bool> _items;

  @override
  void initState() {
    super.initState();
    _items = {for (final item in BackpackChecklistStore.defaultItems) item: false};
    _load();
  }

  Future<void> _load() async {
    final loaded = await BackpackChecklistStore.load();
    if (mounted) setState(() => _items = loaded);
  }

  Future<void> _toggle(String item, bool? value) async {
    setState(() => _items[item] = value ?? false);
    await BackpackChecklistStore.save(_items);
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount = _items.values.where((v) => v).length;

    return HelpSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _EmojiBadge(icon: Icons.backpack_outlined, emoji: '🎒'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mochila de Emergencia',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                    ),
                    const SizedBox(height: 4),
                    _PillBadge(
                      icon: Icons.home_outlined,
                      label: '4 Integrantes en vivienda',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _items.keys)
                FilterChip(
                  label: Text(item),
                  selected: _items[item] ?? false,
                  onSelected: (v) => _toggle(item, v),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.secondaryText),
                  labelStyle: const TextStyle(color: AppColors.text),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                checkedCount == _items.length
                    ? Icons.verified_outlined
                    : Icons.hourglass_bottom_outlined,
                size: 18,
                color: checkedCount == _items.length
                    ? AppColors.primary
                    : AppColors.secondaryText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  checkedCount == _items.length
                      ? 'Validado por Jefe de Grupo'
                      : '$checkedCount de ${_items.length} elementos listos',
                  style: TextStyle(
                    fontSize: 13,
                    color: checkedCount == _items.length
                        ? AppColors.primary
                        : AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmojiBadge extends StatelessWidget {
  const _EmojiBadge({required this.icon, required this.emoji});

  final IconData icon;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary, size: 28),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondaryText.withValues(alpha: 0.3)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.secondaryText),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
