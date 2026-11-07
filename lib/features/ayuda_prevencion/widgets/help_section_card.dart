import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Contenedor base de tarjeta usado por las secciones de Ayuda y Prevención.
class HelpSectionCard extends StatelessWidget {
  const HelpSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondaryText.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
