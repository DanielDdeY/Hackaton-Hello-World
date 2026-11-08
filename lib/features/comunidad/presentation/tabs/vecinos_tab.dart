import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/vecino_ranking.dart';
import '../controllers/comunidad_controller.dart';
import '../pages/vecino_detalle_page.dart';
import '../widgets/reconocimiento_dialog.dart';

class VecinosTab extends StatelessWidget {
  const VecinosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ComunidadController>();
    final buenVecino = controller.buenVecino;
    final ranking = controller.ranking;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => controller.cargarRanking(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Tarjeta de Buen Vecino de la Semana
          if (buenVecino != null) ...[
            _TarjetaBuenVecino(
              buenVecino: buenVecino,
              onNominar: () => mostrarDialogoReconocimiento(
                context,
                controller,
                destinoUid: buenVecino.uid,
                destinoNombre: buenVecino.nombre,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Cabecera del ranking por distrito
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tabla de Vecinos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Chip(
                      avatar: const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF006D77),
                      ),
                      label: Text(controller.distritoRanking),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFFE0F2F1),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: const EdgeInsets.only(right: 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Lista de posiciones
          if (controller.cargando && ranking.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (ranking.isEmpty)
            _EstadoVacioRanking(
              distrito: controller.distritoRanking,
              onReintentar: controller.cargarRanking,
            )
          else
            ...ranking.map((v) => _FilaVecinoRanking(vecino: v)),

          const SizedBox(height: 16),
          Card(
            color: const Color(0xFFF1F8F8),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Color(0xFF006D77),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El ranking se actualiza semanalmente según los puntos XP ganados por participar y ayudar en ${controller.distritoRanking}.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVacioRanking extends StatelessWidget {
  const _EstadoVacioRanking({required this.distrito, required this.onReintentar});

  final String distrito;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.emoji_people_outlined,
              size: 36,
              color: Color(0xFF006D77),
            ),
            const SizedBox(height: 10),
            Text(
              'Aún no hay vecinos en el ranking de $distrito.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaBuenVecino extends StatelessWidget {
  const _TarjetaBuenVecino({required this.buenVecino, required this.onNominar});

  final BuenVecinoSemana buenVecino;
  final VoidCallback onNominar;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFFFB703), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFDF5), Color(0xFFFFF8E7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                final controller = context.read<ComunidadController>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: controller,
                      child: VecinoDetallePage(
                        vecino: VecinoRanking(
                          uid: buenVecino.uid,
                          nombre: buenVecino.nombre,
                          iniciales: buenVecino.iniciales,
                          distrito: buenVecino.distrito,
                          xpPeriodo: 240,
                          posicion: 1,
                          nivel: 8,
                          reconocimientos: buenVecino.votosReconocimiento,
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB703),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buen Vecino de la Semana',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB27B00),
                          ),
                        ),
                        Text(
                          buenVecino.nombre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          buenVecino.distrito,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFB27B00),
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Text(
                '“${buenVecino.motivo}”',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  '${buenVecino.votosReconocimiento} reconocimientos',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8D6200),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onNominar,
                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                  label: const Text('Reconocer a un vecino'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8D6200),
                    side: const BorderSide(color: Color(0xFFFFB703)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaVecinoRanking extends StatelessWidget {
  const _FilaVecinoRanking({required this.vecino});

  final VecinoRanking vecino;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esUsuario = vecino.esUsuarioActual;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: esUsuario ? const Color(0xFFE0F2F1) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            final controller = context.read<ComunidadController>();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: controller,
                  child: VecinoDetallePage(vecino: vecino),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: esUsuario
                    ? theme.colorScheme.primary
                    : Colors.grey.withValues(alpha: 0.2),
                width: esUsuario ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#${vecino.posicion}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: vecino.posicion <= 3
                          ? const Color(0xFFD48B00)
                          : Colors.grey[700],
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: esUsuario
                      ? theme.colorScheme.primary
                      : Colors.grey[300],
                  child: Text(
                    vecino.iniciales,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: esUsuario ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vecino.nombre,
                        style: TextStyle(
                          fontWeight: esUsuario ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Nivel ${vecino.nivel}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (vecino.insignias.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                vecino.insignias.first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8D6200),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _IndicadorTendencia(tendencia: vecino.tendencia),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${vecino.xpPeriodo} XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'esta semana',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndicadorTendencia extends StatelessWidget {
  const _IndicadorTendencia({required this.tendencia});

  final TendenciaRanking tendencia;

  @override
  Widget build(BuildContext context) {
    return switch (tendencia) {
      TendenciaRanking.sube => const Icon(
        Icons.trending_up,
        size: 18,
        color: Color(0xFF2A9D8F),
      ),
      TendenciaRanking.baja => const Icon(
        Icons.trending_down,
        size: 18,
        color: Color(0xFFC0392B),
      ),
      TendenciaRanking.igual => Icon(
        Icons.remove,
        size: 18,
        color: Colors.grey[400],
      ),
    };
  }
}
