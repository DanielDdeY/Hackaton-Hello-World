import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/vecino_ranking.dart';
import '../../domain/repositories/comunidad_repository.dart';
import '../controllers/comunidad_controller.dart';
import '../widgets/reconocimiento_dialog.dart';

/// Ficha completa de un vecino a partir de su fila del ranking.
class VecinoDetallePage extends StatefulWidget {
  const VecinoDetallePage({super.key, required this.vecino});

  final VecinoRanking vecino;

  @override
  State<VecinoDetallePage> createState() => _VecinoDetallePageState();
}

class _VecinoDetallePageState extends State<VecinoDetallePage> {
  late Future<VecinoPerfil?> _perfilFuture;

  @override
  void initState() {
    super.initState();
    final controller = context.read<ComunidadController?>();
    final repo = context.read<ComunidadRepository?>();
    if (controller != null) {
      _perfilFuture = controller.cargarPerfilVecino(widget.vecino.uid);
    } else if (repo != null) {
      _perfilFuture = repo.obtenerVecino(widget.vecino.uid);
    } else {
      _perfilFuture = Future.value(VecinoPerfil.desdeRanking(widget.vecino));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del vecino')),
      body: FutureBuilder<VecinoPerfil?>(
        future: _perfilFuture,
        builder: (context, snapshot) {
          final perfil =
              snapshot.data ?? VecinoPerfil.desdeRanking(widget.vecino);
          final cargandoPerfil =
              snapshot.connectionState != ConnectionState.done;
          final falloPerfil = snapshot.hasError || snapshot.data == null;

          if (falloPerfil && !cargandoPerfil) {
            debugPrint(
              'No se pudo cargar el perfil del vecino: ${snapshot.error}',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Cabecera(perfil: perfil),
              const SizedBox(height: 14),
              if (cargandoPerfil)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Center(child: CircularProgressIndicator()),
                ),
              _TarjetaProgreso(perfil: perfil),
              const SizedBox(height: 14),
              _Estadisticas(perfil: perfil),
              const SizedBox(height: 14),
              if (perfil.insignias.isNotEmpty) ...[
                _Insignias(insignias: perfil.insignias),
                const SizedBox(height: 14),
              ],
              if (perfil.bio.isNotEmpty) ...[
                _TarjetaBio(bio: perfil.bio),
                const SizedBox(height: 14),
              ],
              _TarjetaRanking(perfil: perfil),
              const SizedBox(height: 20),
              _AccionReconocer(perfil: perfil),
              if (falloPerfil && !cargandoPerfil) ...[
                const SizedBox(height: 12),
                Text(
                  'Se muestra la información del ranking porque no se pudo '
                      'cargar el perfil completo.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.perfil});

  final VecinoPerfil perfil;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF006D77), Color(0xFF0E8A93)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              perfil.iniciales,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        perfil.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (perfil.esUsuarioActual) ...[
                      const SizedBox(width: 6),
                      const _ChipEtiqueta(texto: 'Tú'),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        perfil.zona.isEmpty ? perfil.distrito : perfil.zona,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                '#${perfil.posicion}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'en el barrio',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              _IconoTendencia(tendencia: perfil.tendencia, claro: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaProgreso extends StatelessWidget {
  const _TarjetaProgreso({required this.perfil});

  final VecinoPerfil perfil;

  @override
  Widget build(BuildContext context) {
    final xpEnNivel = perfil.xpTotal % 100;
    return Card(
      elevation: 0,
      color: const Color(0xFFF1F8F8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.military_tech,
                  size: 18,
                  color: Color(0xFF006D77),
                ),
                const SizedBox(width: 6),
                Text(
                  'Nivel ${perfil.nivel}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF006D77),
                  ),
                ),
                const Spacer(),
                Text(
                  '$xpEnNivel/100 XP al nivel ${perfil.nivel + 1}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: xpEnNivel / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.white,
              color: const Color(0xFF006D77),
            ),
          ],
        ),
      ),
    );
  }
}

class _Estadisticas extends StatelessWidget {
  const _Estadisticas({required this.perfil});

  final VecinoPerfil perfil;

  static const _datos = <(String, IconData, Color)>[
    ('Favores', Icons.volunteer_activism, Color(0xFF006D77)),
    ('Estrellas', Icons.star_rounded, Color(0xFFD48B00)),
    ('Eventos', Icons.event_available, Color(0xFF2A9D8F)),
    ('Reconoc.', Icons.thumb_up_alt_rounded, Color(0xFF8D6200)),
    ('Racha', Icons.local_fire_department, Color(0xFFC0570F)),
    ('XP total', Icons.bolt_rounded, Color(0xFF5A5A5A)),
  ];

  @override
  Widget build(BuildContext context) {
    final valores = [
      perfil.favoresCompletados,
      perfil.estrellas,
      perfil.eventosAsistidos,
      perfil.reconocimientos,
      perfil.rachaSemanal,
      perfil.xpTotal,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var index = 0; index < _datos.length; index++)
              SizedBox(
                width: ancho,
                child: _TarjetaDato(
                  icono: _datos[index].$2,
                  color: _datos[index].$3,
                  titulo: _datos[index].$1,
                  valor: '${valores[index]}',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TarjetaDato extends StatelessWidget {
  const _TarjetaDato({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icono, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Insignias extends StatelessWidget {
  const _Insignias({required this.insignias});

  final List<String> insignias;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 18,
                  color: Color(0xFFFFB703),
                ),
                SizedBox(width: 6),
                Text(
                  'Insignias',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: insignias.map((badge) => _ChipInsignia(badge)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaBio extends StatelessWidget {
  const _TarjetaBio({required this.bio});

  final String bio;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFBF3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFFFFB703).withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: Color(0xFFB27B00)),
                SizedBox(width: 6),
                Text(
                  'Sobre mí',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFFB27B00),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(bio, style: const TextStyle(fontSize: 13, height: 1.35)),
          ],
        ),
      ),
    );
  }
}

class _TarjetaRanking extends StatelessWidget {
  const _TarjetaRanking({required this.perfil});

  final VecinoPerfil perfil;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF6F9F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.leaderboard, size: 20, color: Color(0xFF006D77)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Puesto #${perfil.posicion} en el ranking del barrio '
                    'con ${perfil.xpPeriodo} XP este mes.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            _IconoTendencia(tendencia: perfil.tendencia),
          ],
        ),
      ),
    );
  }
}

class _AccionReconocer extends StatelessWidget {
  const _AccionReconocer({required this.perfil});

  final VecinoPerfil perfil;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ComunidadController?>();
    if (perfil.esUsuarioActual) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.emoji_people_outlined, size: 18),
        label: const Text('Este vecino eres tú'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: controller == null
          ? null
          : () => mostrarDialogoReconocimiento(
        context,
        controller,
        destinoUid: perfil.uid,
        destinoNombre: perfil.nombre,
      ),
      icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
      label: const Text('Reconocer a este vecino'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
      ),
    );
  }
}

class _ChipInsignia extends StatelessWidget {
  const _ChipInsignia(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 14,
            color: Color(0xFFB27B00),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8D6200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipEtiqueta extends StatelessWidget {
  const _ChipEtiqueta({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB703),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _IconoTendencia extends StatelessWidget {
  const _IconoTendencia({required this.tendencia, this.claro = false});

  final TendenciaRanking tendencia;
  final bool claro;

  @override
  Widget build(BuildContext context) {
    return switch (tendencia) {
      TendenciaRanking.sube => Icon(
        Icons.trending_up,
        size: 18,
        color: claro ? Colors.white : const Color(0xFF2A9D8F),
      ),
      TendenciaRanking.baja => Icon(
        Icons.trending_down,
        size: 18,
        color: claro ? Colors.white70 : const Color(0xFFC0392B),
      ),
      TendenciaRanking.igual => Icon(
        Icons.remove,
        size: 18,
        color: claro ? Colors.white70 : Colors.grey[400],
      ),
    };
  }
}