part of 'main.dart';

class _WrappedBarrio extends StatefulWidget {
  const _WrappedBarrio(this.datos);
  final _DatosBarrio datos;

  @override
  State<_WrappedBarrio> createState() => _WrappedBarrioState();
}

class _WrappedBarrioState extends State<_WrappedBarrio> {
  int _paso = 0;

  @override
  Widget build(BuildContext context) {
    final datos = widget.datos;
    final fecha = DateTime.now();
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    final historias = [
      (
        'Favores completados',
        '${datos.favores}',
        'Cada favor hace más fácil el día de otro vecino.',
        'MuroDeFavores',
        const Color(0xfff6dfec)
      ),
      (
        'Herramientas prestadas',
        '2',
        'Un préstamo puede resolver una tarea en minutos.',
        'ServiciosDeOficios',
        const Color(0xfffbe5cf)
      ),
      (
        'Puntos Star ganados',
        '${250 + datos.puntos - 1250}',
        'Tu participación suma al barrio.',
        'Regalo',
        const Color(0xffe5e2f5)
      ),
      (
        'Puesto en tu grupo',
        '3.º',
        'Gracias por sumar a tu comunidad, ${datos.nombre.split(' ').first}.',
        'MiBarrio',
        const Color(0xffe4e9d5)
      ),
    ];
    final (titulo, valor, detalle, iconoHistoria, fondo) = historias[_paso];
    return Scaffold(
      appBar: AppBar(
          title: const Text('Tu Wrapped del mes'), backgroundColor: cream),
      body: _contenido(
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        label(
            '${meses[fecha.month - 1]} de ${fecha.year} · Datos de demostración',
            14,
            color: muted),
        const SizedBox(height: 14),
        LinearProgressIndicator(
            value: (_paso + 1) / historias.length, color: orange),
        const SizedBox(height: 10),
        label('Historia ${_paso + 1} de ${historias.length}', 13,
            bold: true, color: orange),
        const SizedBox(height: 12),
        tarjeta(
            radius: 24,
            color: fondo,
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(children: [
                icono(iconoHistoria, 46),
                const SizedBox(height: 18),
                label(valor, 60, bold: true, color: orange),
                const SizedBox(height: 8),
                Text(titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 10),
                Text(detalle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: muted)),
              ]),
            )),
        const SizedBox(height: 16),
        _accion(_paso == historias.length - 1 ? 'Volver a Inicio' : 'Siguiente',
            () {
          if (_paso == historias.length - 1) {
            Navigator.pop(context);
          } else {
            setState(() => _paso++);
          }
        }),
        if (_paso > 0)
          OutlinedButton(
              onPressed: () => setState(() => _paso--),
              child: const Text('Atrás')),
      ])),
    );
  }
}
