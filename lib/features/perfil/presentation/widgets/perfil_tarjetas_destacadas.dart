import 'package:flutter/material.dart';

import '../../../economia/domain/entities/nivel_xp.dart';

/// Tarjetas compactas de acceso rápido a la Mascota vecinal y la Mochila de emergencia.
class PerfilTarjetasDestacadas extends StatelessWidget {
  const PerfilTarjetasDestacadas({
    super.key,
    required this.xp,
    required this.bonoMochilaReclamado,
    required this.itemsMochilaListos,
    required this.onAbrirMascota,
    required this.onAbrirMochila,
  });

  final int xp;
  final bool bonoMochilaReclamado;
  final int itemsMochilaListos;
  final VoidCallback onAbrirMascota;
  final VoidCallback onAbrirMochila;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mascotaActiva = NivelXp.mascotaDesbloqueada(xp);

    return Column(
      children: [
        // Tarjeta Cuy
        Card(
          elevation: 0,
          color: const Color(0xFFF0FDF4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFBBF7D0)),
          ),
          child: InkWell(
            onTap: onAbrirMascota,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pets, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Mi Mascota Vecinal',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!mascotaActiva)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Nivel 2',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mascotaActiva
                              ? '¡Tu cuy está activo! Cuídalo, aliméntalo y participa.'
                              : 'Alcanza el Nivel 2 (210 XP) para desbloquear a tu compañero.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Tarjeta Mochila
        Card(
          elevation: 0,
          color: const Color(0xFFFFFBEB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFFDE68A)),
          ),
          child: InkWell(
            onTap: onAbrirMochila,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.backpack_outlined, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Mochila de Emergencia',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (bonoMochilaReclamado)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Verificada',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF15803D),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bonoMochilaReclamado
                              ? 'Mochila completa y verificada (+50 fichas obtenidas).'
                              : '$itemsMochilaListos/10 elementos listos. ¡Complétala para ganar +50 fichas!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

