import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../models/emergency_contact.dart';

/// Fila del directorio de emergencia con botón de llamada.
class EmergencyContactTile extends StatelessWidget {
  const EmergencyContactTile({super.key, required this.contact});

  final EmergencyContact contact;

  Future<void> _call(BuildContext context) async {
    final uri = contact.dialUri;
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo llamar a ${contact.name}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(contact.icon, color: AppColors.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    fontSize: 15,
                  ),
                ),
                if (contact.description != null)
                  Text(
                    contact.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                Text(
                  contact.phoneNumber ?? '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: contact.canCall ? AppColors.primary : AppColors.secondaryText,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: contact.canCall ? () => _call(context) : null,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.phone,
                  color: contact.canCall
                      ? AppColors.surface
                      : AppColors.surface.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
