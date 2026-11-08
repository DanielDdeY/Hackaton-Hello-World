import 'package:flutter/material.dart';

import '../../../domain/entities/service_availability.dart';
import '../../../domain/entities/service_post_data.dart';
import 'service_availability_validator.dart';
import 'service_form_controller.dart';

class ServiceAvailabilityFields extends StatelessWidget {
  const ServiceAvailabilityFields({super.key, required this.controller});

  static const _dayLabels = {
    Weekday.monday: 'Lun',
    Weekday.tuesday: 'Mar',
    Weekday.wednesday: 'Mié',
    Weekday.thursday: 'Jue',
    Weekday.friday: 'Vie',
    Weekday.saturday: 'Sáb',
    Weekday.sunday: 'Dom',
  };

  final ServiceFormController controller;

  Future<void> _pickTime(
    FormFieldState<ServiceAvailability> field, {
    required String label,
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    FocusScope.of(field.context).unfocus();
    final time = await showTimePicker(
      context: field.context,
      initialTime: initialTime,
      helpText: label,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (!field.mounted ||
        time == null ||
        controller.mode != ServiceMode.provideService) {
      return;
    }
    onSelected(time);
    field.didChange(controller.availability);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = controller.startTime;
    final end = controller.endTime;

    return FormField<ServiceAvailability>(
      initialValue: controller.availability,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      validator: (_) => controller.mode == ServiceMode.provideService
          ? ServiceAvailabilityValidator.validate(controller.availability)
          : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Disponibilidad (Opcional)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final day in _dayLabels.entries)
                FilterChip(
                  label: Text(day.value),
                  selected: controller.days.contains(day.key),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) {
                    controller.toggleDay(day.key);
                    field.didChange(controller.availability);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule_outlined),
            label: Text(
              start == null
                  ? 'Hora de inicio'
                  : 'Inicio: ${start.format(context)}',
            ),
            onPressed: () => _pickTime(
              field,
              label: 'Hora de inicio',
              initialTime: start ?? const TimeOfDay(hour: 9, minute: 0),
              onSelected: controller.setStartTime,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule_outlined),
            label: Text(
              end == null ? 'Hora de fin' : 'Fin: ${end.format(context)}',
            ),
            onPressed: () => _pickTime(
              field,
              label: 'Hora de fin',
              initialTime: end ?? const TimeOfDay(hour: 17, minute: 0),
              onSelected: controller.setEndTime,
            ),
          ),
          if (controller.availability != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  controller.clearAvailability();
                  field.didChange(null);
                },
                child: const Text('Limpiar horario'),
              ),
            ),
          if (field.errorText case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
