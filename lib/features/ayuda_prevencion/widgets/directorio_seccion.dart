import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/peru_emergency_numbers.dart';
import 'emergency_contact_tile.dart';
import 'help_section_card.dart';

/// Sección "Directorio de Emergencia" con números nacionales (offline).
class DirectorioSeccion extends StatelessWidget {
  const DirectorioSeccion({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_in_talk, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Directorio de Emergencia',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                    ),
                    const Text(
                      '(Disponible Offline)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.secondaryText),
          for (final contact in PeruEmergencyNumbers.contacts)
            EmergencyContactTile(contact: contact),
        ],
      ),
    );
  }
}
