part of 'home.dart';

const _pasos = [
  (
    'Tu perfil',
    'Aquí ves tu nombre, tu nivel y los puntos que ganas al participar.',
  ),
  (
    'SOS y notificaciones',
    'Usa SOS para pedir ayuda urgente a tu grupo. En la campana encontrarás tus notificaciones.',
  ),
  (
    'Tu Mascota: El Cuy',
    'Tu compañero del barrio. Al alcanzar el nivel 2 podrás visitarlo, abrir cajas de sorpresas y personalizarlo con accesorios.',
  ),
  (
    'Muévete por la app',
    'Usa la barra inferior para explorar Mapa, Comunidad, Ayuda y Publicar.',
  ),
];

class _TutorialInicio extends StatelessWidget {
  const _TutorialInicio({
    required this.paso,
    required this.zonas,
    required this.siguiente,
    required this.atras,
    required this.cerrar,
  });

  final int paso;
  final List<Rect> zonas;
  final VoidCallback siguiente;
  final VoidCallback atras;
  final VoidCallback cerrar;

  @override
  Widget build(BuildContext context) {
    final (titulo, descripcion) = _pasos[paso];
    final ultimo = paso == _pasos.length - 1;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ModalBarrier(dismissible: false),
        IgnorePointer(child: CustomPaint(painter: _VeloTutorial(zonas))),
        CustomSingleChildLayout(
          delegate: _PosicionTutorial(zonas, MediaQuery.paddingOf(context)),
          child: Material(
            color: paper,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Semantics(
              container: true,
              liveRegion: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: label(
                            'RECORRIDO DE INICIO  ${paso + 1} / ${_pasos.length}',
                            11,
                            bold: true,
                            color: orange,
                          ),
                        ),
                        TextButton(
                          onPressed: cerrar,
                          child: const Text('Omitir'),
                        ),
                      ],
                    ),
                    label(titulo, 21, bold: true),
                    const SizedBox(height: 8),
                    label(descripcion, 14),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          if (paso > 0)
                            OutlinedButton(
                              onPressed: atras,
                              child: const Text('Atrás'),
                            ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: orange,
                            ),
                            onPressed: ultimo ? cerrar : siguiente,
                            child: Text(
                              ultimo ? 'Empezar a explorar' : 'Siguiente',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VeloTutorial extends CustomPainter {
  const _VeloTutorial(this.zonas);

  final List<Rect> zonas;

  @override
  void paint(Canvas canvas, Size size) {
    var velo = Path()..addRect(Offset.zero & size);
    final bordes = Paint()
      ..color = const Color(0xffffbe5b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final zona in zonas) {
      final borde = RRect.fromRectAndRadius(zona, const Radius.circular(16));
      velo = Path.combine(
        PathOperation.difference,
        velo,
        Path()..addRRect(borde),
      );
      canvas.drawRRect(borde, bordes);
    }
    canvas.drawPath(velo, Paint()..color = const Color(0xa31e1813));
  }

  @override
  bool shouldRepaint(_VeloTutorial oldDelegate) => oldDelegate.zonas != zonas;
}

class _PosicionTutorial extends SingleChildLayoutDelegate {
  const _PosicionTutorial(this.zonas, this.inset);

  final List<Rect> zonas;
  final EdgeInsets inset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final ancho = (constraints.maxWidth - inset.horizontal - 36)
        .clamp(0.0, 354.0)
        .toDouble();
    final alto = (constraints.maxHeight - inset.vertical - 32)
        .clamp(0.0, 290.0)
        .toDouble();
    return BoxConstraints(minWidth: ancho, maxWidth: ancho, maxHeight: alto);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final limiteSuperior = inset.top + 12;
    final limiteInferior = size.height - inset.bottom - 12;
    final debajo = zonas.isEmpty
        ? limiteSuperior
        : zonas.map((z) => z.bottom).reduce(math.max) + 14;
    final encima = zonas.isEmpty
        ? limiteSuperior
        : zonas.map((z) => z.top).reduce(math.min) - 14 - childSize.height;
    final maxY = math.max(limiteSuperior, limiteInferior - childSize.height);
    final y = debajo <= maxY ? debajo : encima;
    return Offset(
      (size.width - childSize.width) / 2,
      y.clamp(limiteSuperior, maxY).toDouble(),
    );
  }

  @override
  bool shouldRelayout(_PosicionTutorial oldDelegate) =>
      oldDelegate.zonas != zonas || oldDelegate.inset != inset;
}
