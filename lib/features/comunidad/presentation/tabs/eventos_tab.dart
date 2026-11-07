import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/evento_comunitario.dart';
import '../controllers/comunidad_controller.dart';

class EventosTab extends StatelessWidget {
  const EventosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ComunidadController>();
    final eventos = controller.eventos;

    return RefreshIndicator(
      onRefresh: controller.cargarEventos,
      child: controller.cargando && eventos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : eventos.isEmpty
              ? const _EstadoVacioEventos()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: eventos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _TarjetaEvento(evento: eventos[index]);
                  },
                ),
    );
  }
}

class _TarjetaEvento extends StatelessWidget {
  const _TarjetaEvento({required this.evento});

  final EventoComunitario evento;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.read<ComunidadController>();

    final dia = evento.fecha.day.toString().padLeft(2, '0');
    final mes = _nombreMesCorto(evento.fecha.month);
    final hora = '${evento.fecha.hour.toString().padLeft(2, '0')}:${evento.fecha.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bloque de fecha tipo calendario
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dia,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        mes,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              evento.tipo.etiqueta,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF006D77),
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Opciones',
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            onSelected: (val) {
                              if (val == 'reportar') {
                                _mostrarDialogoReporteEvento(context, evento.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'reportar',
                                child: Row(
                                  children: [
                                    Icon(Icons.flag_outlined, size: 16, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Reportar', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        evento.titulo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              evento.descripcion,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(hora, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.place_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    evento.lugar,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${evento.asistenciasVoy} confirmados · ${evento.asistenciasInteresa} interesados',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                // Botón "Me interesa"
                IconButton(
                  tooltip: 'Me interesa',
                  icon: Icon(
                    evento.miRespuesta == RespuestaEvento.meInteresa
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: evento.miRespuesta == RespuestaEvento.meInteresa
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                  onPressed: () {
                    final nueva = evento.miRespuesta == RespuestaEvento.meInteresa
                        ? RespuestaEvento.ninguna
                        : RespuestaEvento.meInteresa;
                    controller.responderEvento(evento.id, nueva);
                  },
                ),
                // Botón "Voy"
                FilledButton.tonalIcon(
                  onPressed: () {
                    final nueva = evento.miRespuesta == RespuestaEvento.voy
                        ? RespuestaEvento.ninguna
                        : RespuestaEvento.voy;
                    controller.responderEvento(evento.id, nueva);
                  },
                  icon: Icon(
                    evento.miRespuesta == RespuestaEvento.voy
                        ? Icons.check_circle
                        : Icons.event_available,
                    size: 16,
                  ),
                  label: Text(evento.miRespuesta == RespuestaEvento.voy ? 'Voy' : 'Asistiré'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _nombreMesCorto(int mes) {
    const meses = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SET', 'OCT', 'NOV', 'DIC'];
    return meses[mes - 1];
  }
}

class _EstadoVacioEventos extends StatelessWidget {
  const _EstadoVacioEventos();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 54, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No hay eventos programados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Las faenas, talleres y reuniones de la junta vecinal aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

void _mostrarDialogoReporteEvento(BuildContext context, String eventoId) {
  String motivo = 'Información no verídica o suspendida';
  final motivos = [
    'Información no verídica o suspendida',
    'Convocatoria no autorizada',
    'Contenido ofensivo o spam',
  ];

  showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Reportar evento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'El reporte será revisado por los delegados de la junta vecinal.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: motivo,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del reporte',
                    border: OutlineInputBorder(),
                  ),
                  items: motivos
                      .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => motivo = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD62828)),
                onPressed: () async {
                  final controller = dialogCtx.read<ComunidadController>();
                  await controller.repository.reportarContenido('evento', eventoId, motivo);
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Evento enviado a revisión.'),
                        backgroundColor: Color(0xFFD62828),
                      ),
                    );
                  }
                },
                child: const Text('Enviar reporte'),
              ),
            ],
          );
        },
      );
    },
  );
}

