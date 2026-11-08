import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/vecino_ranking.dart';
import '../controllers/comunidad_controller.dart';

class VecinosTab extends StatelessWidget {
  const VecinosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ComunidadController>();
    final buenVecino = controller.buenVecino;
    final ranking = controller.ranking;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => controller.cargarRanking(controller.ambitoRanking),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Tarjeta de Buen Vecino de la Semana
          if (buenVecino != null) ...[
            _TarjetaBuenVecino(
              buenVecino: buenVecino,
              onNominar: () => _mostrarDialogoNominar(context, controller),
            ),
            const SizedBox(height: 16),
          ],

          // Cabecera de Ranking y Selector de ámbito
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tabla de Vecinos',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cuadra', label: Text('Cuadra')),
                  ButtonSegment(value: 'barrio', label: Text('Barrio')),
                ],
                selected: {controller.ambitoRanking},
                onSelectionChanged: (set) {
                  controller.cargarRanking(set.first);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Lista de posiciones
          if (controller.cargando && ranking.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
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
                  const Icon(Icons.info_outline, size: 20, color: Color(0xFF006D77)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El ranking se actualiza semanalmente según los puntos XP ganados por participar y ayudar.',
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFB703),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
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
                        buenVecino.cuadraNombre,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8D6200)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: esUsuario ? const Color(0xFFE0F2F1) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esUsuario ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.2),
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
                color: vecino.posicion <= 3 ? const Color(0xFFD48B00) : Colors.grey[700],
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: esUsuario ? theme.colorScheme.primary : Colors.grey[300],
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
                Text(
                  '${vecino.cuadraNombre} · Nivel ${vecino.nivel}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${vecino.xpPeriodo} XP',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Text('esta semana', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

void _mostrarDialogoNominar(BuildContext context, ComunidadController controller) {
  final motivoCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        title: const Text('Reconocer a un buen vecino'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tienes 1 reconocimiento disponible esta semana. Destaca una buena acción vecinal:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: motivoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ej. Ayudó a limpiar el pasaje tras la lluvia...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 6) {
                    return 'Ingresa al menos una frase describiendo el motivo.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await controller.nominarBuenVecino('usr_otro', motivoCtrl.text.trim());
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Reconocimiento enviado con éxito!'),
                    backgroundColor: Color(0xFF2A9D8F),
                  ),
                );
              }
            },
            child: const Text('Enviar reconocimiento'),
          ),
        ],
      );
    },
  );
}

