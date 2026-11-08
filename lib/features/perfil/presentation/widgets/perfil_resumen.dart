import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Tarjeta de resumen económico con XP del mes, fichas y valoración en estrellas.
class PerfilResumen extends StatelessWidget {
  const PerfilResumen({
    super.key,
    required this.xpMes,
    required this.fichas,
    required this.estrellas,
    required this.totalResenas,
  });

  final int xpMes;
  final int fichas;
  final double estrellas;
  final int totalResenas;

  Widget _metrica({
    required BuildContext context,
    required Widget icono,
    required String valor,
    required String etiqueta,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icono,
          const SizedBox(height: 6),
          Text(
            valor,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            _metrica(
              context: context,
              icono: const Icon(Icons.bolt, color: Color(0xFFD97706), size: 24),
              valor: '$xpMes',
              etiqueta: 'XP del mes',
            ),
            Container(width: 1, height: 36, color: const Color(0xFFE5E7EB)),
            _metrica(
              context: context,
              icono: SvgPicture.asset('assets/ficha.svg', width: 22, height: 22),
              valor: '$fichas',
              etiqueta: 'Fichas',
            ),
            Container(width: 1, height: 36, color: const Color(0xFFE5E7EB)),
            _metrica(
              context: context,
              icono: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
              valor: totalResenas > 0 ? estrellas.toStringAsFixed(1) : '-',
              etiqueta: totalResenas > 0 ? '★ ($totalResenas)' : 'Valoración',
            ),
          ],
        ),
      ),
    );
  }
}

