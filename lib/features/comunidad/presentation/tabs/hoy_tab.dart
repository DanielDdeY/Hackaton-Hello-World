import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/favor.dart';
import '../../domain/entities/resumen_hoy.dart';
import '../../../community/presentation/community_sos_section.dart';
import '../controllers/comunidad_controller.dart';

class HoyTab extends StatelessWidget {
  const HoyTab({super.key, required this.onIrAFavores, required this.onIrAEventos});

  final VoidCallback onIrAFavores;
  final VoidCallback onIrAEventos;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ComunidadController>();
    final resumen = controller.resumenHoy;

    if (controller.cargando && resumen == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (resumen == null) {
      return const Center(child: Text('No hay información disponible.'));
    }

    return RefreshIndicator(
      onRefresh: controller.cargarResumenHoy,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const CommunitySosSection(),

          // Banner de alerta comunitaria (RF-01 / RN-19)
          if (resumen.alertaActiva != null) ...[
            _BannerAlerta(alerta: resumen.alertaActiva!),
            const SizedBox(height: 14),
          ],

          // Favores en curso del vecino
          if (resumen.favoresEnCurso.isNotEmpty) ...[
            _SeccionCabecera(
              titulo: 'Mis compromisos activos',
              icono: Icons.pending_actions_outlined,
            ),
            const SizedBox(height: 8),
            for (final f in resumen.favoresEnCurso) ...[
              _TarjetaFavorActivo(favor: f),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
          ],

          // Impulso vecinal: Pedidos cercanos que requieren apoyo
          _SeccionCabecera(
            titulo: 'Necesitan una mano en tu cuadra',
            icono: Icons.handshake_outlined,
            accionTexto: 'Ver todos',
            onAccion: onIrAFavores,
          ),
          const SizedBox(height: 8),
          if (resumen.favoresCercanos.isEmpty)
            const _TarjetaVacia(mensaje: 'No hay pedidos pendientes en tu zona inmediata.')
          else
            for (final f in resumen.favoresCercanos) ...[
              _TarjetaFavorCercano(favor: f, onVerMas: onIrAFavores),
              const SizedBox(height: 8),
            ],

          const SizedBox(height: 14),

          // Meta colectiva de la cuadra (Gamificación con impacto social)
          _TarjetaProgresoCuadra(stats: resumen.estadisticasCuadra),

          const SizedBox(height: 14),

          // Próximas actividades barriales
          _SeccionCabecera(
            titulo: 'Próximos eventos',
            icono: Icons.event_outlined,
            accionTexto: 'Calendario',
            onAccion: onIrAEventos,
          ),
          const SizedBox(height: 8),
          for (final ev in resumen.eventosProximos) ...[
            Card(
              elevation: 0.5,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(Icons.groups, color: Color(0xFF006D77)),
                ),
                title: Text(ev.titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${ev.cuadraNombre} · ${ev.lugar}', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: onIrAEventos,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _BannerAlerta extends StatelessWidget {
  const _BannerAlerta({required this.alerta});
  final AlertaActiva alerta;

  @override
  Widget build(BuildContext context) {
    final esEmergencia = alerta.esModoEmergencia;
    final colorFondo = esEmergencia ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3CD);
    final colorBorde = esEmergencia ? const Color(0xFFD62828) : const Color(0xFFFFB703);
    final icono = esEmergencia ? Icons.warning_amber_rounded : Icons.campaign_outlined;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorBorde, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: colorBorde, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.titulo,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorBorde),
                ),
                const SizedBox(height: 3),
                Text(
                  alerta.descripcion,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aviso de: ${alerta.autor}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionCabecera extends StatelessWidget {
  const _SeccionCabecera({
    required this.titulo,
    required this.icono,
    this.accionTexto,
    this.onAccion,
  });

  final String titulo;
  final IconData icono;
  final String? accionTexto;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: const Color(0xFF006D77)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        if (accionTexto != null && onAccion != null)
          TextButton(
            onPressed: onAccion,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(accionTexto!),
          ),
      ],
    );
  }
}

class _TarjetaFavorActivo extends StatelessWidget {
  const _TarjetaFavorActivo({required this.favor});
  final Favor favor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF0FDF4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF2A9D8F), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2A9D8F)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    favor.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Text(
                  '+${favor.monedasRecompensa} pts',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006D77)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Vecino: ${favor.solicitanteNombre} · ${favor.ubicacionExacta ?? favor.ubicacionAproximada}',
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaFavorCercano extends StatelessWidget {
  const _TarjetaFavorCercano({required this.favor, required this.onVerMas});
  final Favor favor;
  final VoidCallback onVerMas;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(favor.titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(
          '${favor.ubicacionAproximada} · ${favor.tamano.etiqueta}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '+${favor.monedasRecompensa} pts',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB27B00)),
          ),
        ),
        onTap: onVerMas,
      ),
    );
  }
}

class _TarjetaProgresoCuadra extends StatelessWidget {
  const _TarjetaProgresoCuadra({required this.stats});
  final EstadisticasCuadra stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF006D77), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seguridad y Solidaridad: ${stats.cuadraNombre}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DatoEstadistico(
                  valor: '${stats.porcentajeMochilaPreparada}%',
                  etiqueta: 'Mochilas listas',
                ),
                Container(height: 30, width: 1, color: Colors.grey[300]),
                _DatoEstadistico(
                  valor: '${stats.favoresCompletadosSemana}',
                  etiqueta: 'Favores resueltos',
                ),
                Container(height: 30, width: 1, color: Colors.grey[300]),
                _DatoEstadistico(
                  valor: '${stats.vecinosActivos}',
                  etiqueta: 'Vecinos activos',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DatoEstadistico extends StatelessWidget {
  const _DatoEstadistico({required this.valor, required this.etiqueta});
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF006D77))),
        const SizedBox(height: 2),
        Text(etiqueta, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _TarjetaVacia extends StatelessWidget {
  const _TarjetaVacia({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(mensaje, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}
