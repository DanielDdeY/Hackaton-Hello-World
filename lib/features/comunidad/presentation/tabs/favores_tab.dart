import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/favor.dart';
import '../controllers/comunidad_controller.dart';

class FavoresTab extends StatelessWidget {
  const FavoresTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ComunidadController>();
    final favores = controller.favores;

    return RefreshIndicator(
      onRefresh: controller.cargarFavores,
      child: Column(
        children: [
          _BarraFiltros(controller: controller),
          Expanded(
            child: controller.cargando && favores.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : favores.isEmpty
                    ? _EstadoVacioFavores(
                        onReset: () => controller.setFiltrosFavores(
                          categoria: null,
                          tamano: null,
                          soloConCupo: false,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: favores.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _TarjetaFavor(favor: favores[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({required this.controller});

  final ComunidadController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Solo con cupo'),
            selected: controller.filtroSoloConCupo,
            onSelected: (val) => controller.setFiltrosFavores(soloConCupo: val),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<TamanoFavor?>(
            tooltip: 'Filtrar por tamaño',
            initialValue: controller.filtroTamano,
            onSelected: (tamano) => controller.setFiltrosFavores(tamano: tamano),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Cualquier tamaño')),
              ...TamanoFavor.values.map(
                (t) => PopupMenuItem(
                  value: t,
                  child: Text('${t.etiqueta} (${t.duracionAprox})'),
                ),
              ),
            ],
            child: Chip(
              avatar: const Icon(Icons.timer_outlined, size: 16),
              label: Text(
                controller.filtroTamano?.etiqueta ?? 'Tamaño',
                style: TextStyle(
                  fontWeight: controller.filtroTamano != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<CategoriaFavor?>(
            tooltip: 'Filtrar por categoría',
            initialValue: controller.filtroCategoria,
            onSelected: (cat) => controller.setFiltrosFavores(categoria: cat),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todas las categorías')),
              ...CategoriaFavor.values.map(
                (c) => PopupMenuItem(value: c, child: Text(c.etiqueta)),
              ),
            ],
            child: Chip(
              avatar: const Icon(Icons.category_outlined, size: 16),
              label: Text(
                controller.filtroCategoria?.etiqueta ?? 'Categoría',
                style: TextStyle(
                  fontWeight: controller.filtroCategoria != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (controller.filtroCategoria != null ||
              controller.filtroTamano != null ||
              controller.filtroSoloConCupo) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Limpiar filtros',
              onPressed: () => controller.setFiltrosFavores(
                categoria: null,
                tamano: null,
                soloConCupo: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaFavor extends StatelessWidget {
  const _TarjetaFavor({required this.favor});

  final Favor favor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tieneCupo = favor.tieneCupo;

    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarDetalleFavor(context, favor),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favor.titulo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          favor.solicitanteNombre,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BadgeRecompensa(
                    monedas: favor.monedasRecompensa,
                    xp: favor.xpRecompensa,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                favor.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      favor.ubicacionAproximada,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _BadgeCupo(
                    tomados: favor.cuposTomados,
                    totales: favor.cuposTotales,
                    tieneCupo: tieneCupo,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeRecompensa extends StatelessWidget {
  const _BadgeRecompensa({required this.monedas, required this.xp});

  final int monedas;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB703), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFD48B00)),
          const SizedBox(width: 4),
          Text(
            '+$monedas pts',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A4A00),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($xp XP)',
            style: const TextStyle(fontSize: 10, color: Color(0xFF7A4A00)),
          ),
        ],
      ),
    );
  }
}

class _BadgeCupo extends StatelessWidget {
  const _BadgeCupo({
    required this.tomados,
    required this.totales,
    required this.tieneCupo,
  });

  final int tomados;
  final int totales;
  final bool tieneCupo;

  @override
  Widget build(BuildContext context) {
    final color = tieneCupo ? const Color(0xFF2A9D8F) : const Color(0xFF9E9E9E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        tieneCupo ? 'Cupos: ${totales - tomados}/$totales' : 'Cupos llenos',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _EstadoVacioFavores extends StatelessWidget {
  const _EstadoVacioFavores({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volunteer_activism_outlined, size: 54, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No hay favores con estos filtros',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Prueba restableciendo los filtros para ver todos los pedidos del barrio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onReset,
              child: const Text('Ver todos los favores'),
            ),
          ],
        ),
      ),
    );
  }
}

void _mostrarDetalleFavor(BuildContext context, Favor favor) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (modalCtx) {
      return _DetalleFavorSheet(favor: favor);
    },
  );
}

class _DetalleFavorSheet extends StatefulWidget {
  const _DetalleFavorSheet({required this.favor});
  final Favor favor;

  @override
  State<_DetalleFavorSheet> createState() => _DetalleFavorSheetState();
}

class _DetalleFavorSheetState extends State<_DetalleFavorSheet> {
  bool _procesando = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favor = widget.favor;
    final controller = context.watch<ComunidadController>();
    final participanteActual = favor.participantes.where(
      (p) => p.uid == controller.resumenHoy?.favoresEnCurso.firstOrNull?.participantes.firstOrNull?.uid || p.uid == 'usr_actual',
    ).firstOrNull;

    final estaParticipando = participanteActual != null;
    final haTerminado = participanteActual?.estado == 'terminado';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    favor.titulo,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _BadgeRecompensa(
                  monedas: favor.monedasRecompensa,
                  xp: favor.xpRecompensa,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Solicitado por: ${favor.solicitanteNombre}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
            ),
            const Divider(height: 24),
            Text(
              favor.descripcion,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            _FilaInfo(
              icono: Icons.timer_outlined,
              titulo: 'Tamaño y duración:',
              valor: '${favor.tamano.etiqueta} (${favor.tamano.duracionAprox})',
            ),
            const SizedBox(height: 8),
            _FilaInfo(
              icono: Icons.place_outlined,
              titulo: estaParticipando ? 'Dirección exacta:' : 'Ubicación aprox.:',
              valor: estaParticipando && favor.ubicacionExacta != null
                  ? favor.ubicacionExacta!
                  : favor.ubicacionAproximada,
            ),
            const SizedBox(height: 8),
            _FilaInfo(
              icono: Icons.people_outline,
              titulo: 'Cupos disponibles:',
              valor: '${favor.cuposDisponibles} de ${favor.cuposTotales}',
            ),
            const SizedBox(height: 20),

            // Acciones según estado (Regla de 3 toques)
            if (!estaParticipando && favor.tieneCupo) ...[
              FilledButton.icon(
                onPressed: _procesando
                    ? null
                    : () async {
                        setState(() => _procesando = true);
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await controller.aceptarFavor(favor.id);
                          if (mounted) navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('¡Favor aceptado! Ya puedes coordinar con el vecino.'),
                              backgroundColor: Color(0xFF2A9D8F),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        } finally {
                          if (mounted) setState(() => _procesando = false);
                        }
                      },
                icon: const Icon(Icons.handshake_outlined),
                label: const Text('Aceptar favor'),
              ),
            ] else if (estaParticipando && !haTerminado) ...[
              FilledButton.icon(
                onPressed: _procesando
                    ? null
                    : () async {
                        setState(() => _procesando = true);
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await controller.marcarTerminado(favor.id);
                          if (mounted) navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Marcado como terminado. Esperando confirmación del vecino.'),
                              backgroundColor: Color(0xFF006D77),
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _procesando = false);
                        }
                      },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Marcar como terminado'),
              ),
            ] else if (estaParticipando && haTerminado) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top, color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Completado por tu parte. En espera de confirmación vecinal para liberar tus puntos.',
                        style: TextStyle(color: Color(0xFF1B5E20), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botón de WhatsApp solo visible si ya aceptó (RN-07 / RF-07)
            if (estaParticipando) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Abriendo WhatsApp con ${favor.solicitanteTelefono}...'),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_outlined, color: Colors.green),
                label: Text('Contactar por WhatsApp (${favor.solicitanteTelefono})'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaInfo extends StatelessWidget {
  const _FilaInfo({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

