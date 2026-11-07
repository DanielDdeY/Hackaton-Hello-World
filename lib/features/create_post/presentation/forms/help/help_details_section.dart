import 'package:flutter/material.dart';

import '../../../../../core/widgets/collapsible_section.dart';
import 'help_form_controller.dart';

class HelpDetailsSection extends StatelessWidget {
  const HelpDetailsSection({super.key, required this.controller});

  final HelpFormController controller;

  Future<void> _pickDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = controller.neededBy;
    final date = await showDatePicker(
      context: context,
      helpText: 'Fecha requerida',
      initialDate: selected != null && !selected.isBefore(today)
          ? selected
          : today,
      firstDate: today,
      lastDate: DateTime(9999, 12, 31),
    );
    if (context.mounted && date != null) controller.setNeededBy(date);
  }

  @override
  Widget build(BuildContext context) {
    final date = controller.neededBy;
    final count = controller.peopleCount;
    final textTheme = Theme.of(context).textTheme;
    final dateLabel = date == null
        ? 'Elegir fecha'
        : MaterialLocalizations.of(context).formatMediumDate(date);
    final stepperStyle = IconButton.styleFrom(
      minimumSize: const Size.square(48),
    );

    return CollapsibleSection(
      label: 'Detalles',
      expanded: controller.detailsExpanded,
      onChanged: controller.setDetailsExpanded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Fecha requerida (Opcional)', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(dateLabel),
                ),
              ),
              if (date != null)
                IconButton(
                  tooltip: 'Quitar fecha',
                  onPressed: () => controller.setNeededBy(null),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Cantidad de personas (Opcional)', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton.outlined(
                style: stepperStyle,
                tooltip: 'Restar persona',
                onPressed: count != null && count > 1
                    ? () => controller.setPeopleCount(count - 1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Semantics(
                liveRegion: true,
                child: Text(count?.toString() ?? 'Sin indicar'),
              ),
              IconButton.outlined(
                style: stepperStyle,
                tooltip: 'Agregar persona',
                onPressed: () => controller.setPeopleCount((count ?? 0) + 1),
                icon: const Icon(Icons.add),
              ),
              if (count != null)
                IconButton(
                  tooltip: 'Quitar cantidad',
                  onPressed: () => controller.setPeopleCount(null),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.locationController,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Ubicación específica (Opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
