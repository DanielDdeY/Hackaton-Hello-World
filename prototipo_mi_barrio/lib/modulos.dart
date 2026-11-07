part of 'main.dart';

class _PerfilVecino extends StatelessWidget {
  const _PerfilVecino(this.datos, this.repetirTutorial);
  final _DatosBarrio datos;
  final VoidCallback repetirTutorial;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: datos,
        builder: (context, _) => Scaffold(
          appBar:
              AppBar(title: const Text('Mi perfil'), backgroundColor: cream),
          body: _contenido(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tarjeta(
                  radius: 16,
                  border: true,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _avatarVecino(datos.iniciales, datos.foto, 45),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(datos.nombre, 19, bold: true),
                              label('Jefe de grupo · Demo', 13, color: muted),
                              const SizedBox(height: 8),
                              _accion(
                                'Editar perfil',
                                () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => _EditarVecino(datos),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _bloque('Mi comunidad', datos.zona),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: const Text('Nivel 25')),
                    Chip(label: Text('Puntos Star: ${datos.puntos}')),
                    Chip(label: Text('Favores: ${datos.favores}')),
                  ],
                ),
                const SizedBox(height: 12),
                _bloque(
                  'Sobre mí',
                  datos.bio.isEmpty
                      ? 'Agrega una presentación en Editar perfil.'
                      : datos.bio,
                ),
                const SizedBox(height: 18),
                label('Mi actividad', 21, bold: true),
                for (final (tipo, titulo) in const [
                  ('Negocio', 'Mis negocios'),
                  ('Misión', 'Mis misiones'),
                  ('Ayuda', 'Mis ayudas activas'),
                  ('Anuncio', 'Mis anuncios'),
                ]) ...[
                  const SizedBox(height: 12),
                  label(titulo, 15, bold: true, color: orange),
                  for (final item in datos.publicaciones.where(
                    (p) =>
                        p.tipo == tipo &&
                        (tipo != 'Ayuda' || p.estado != 'Completada'),
                  )) ...[
                    const SizedBox(height: 6),
                    _bloque(
                      item.titulo,
                      '${item.descripcion}\n${item.estado}',
                      onTap: () => _abrirPublicacion(context, datos, item),
                    ),
                  ],
                  if (!datos.publicaciones.any(
                    (p) =>
                        p.tipo == tipo &&
                        (tipo != 'Ayuda' || p.estado != 'Completada'),
                  ))
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Sin publicaciones activas.'),
                    ),
                ],
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    repetirTutorial();
                  },
                  child: const Text('Ver tutorial de nuevo'),
                ),
              ],
            ),
          ),
        ),
      );
}

Widget _avatarVecino(String iniciales, bool foto, double radio) => CircleAvatar(
      radius: radio,
      backgroundColor: foto ? const Color(0xffdfece0) : const Color(0xfff4d1ac),
      child: foto
          ? Icon(Icons.person, size: radio, color: const Color(0xff3f684b))
          : label(iniciales, radio * .57, bold: true, color: orange),
    );

class _EditarVecino extends StatefulWidget {
  const _EditarVecino(this.datos);
  final _DatosBarrio datos;

  @override
  State<_EditarVecino> createState() => _EditarVecinoState();
}

class _EditarVecinoState extends State<_EditarVecino> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.datos.nombre);
  late final _bio = TextEditingController(text: widget.datos.bio);
  late bool _foto = widget.datos.foto;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar:
            AppBar(title: const Text('Editar perfil'), backgroundColor: cream),
        body: _contenido(
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _avatarVecino(widget.datos.iniciales, _foto, 30),
                    const SizedBox(width: 14),
                    OutlinedButton(
                      onPressed: () async {
                        final opcion = await showDialog<bool>(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: const Text('Cambiar foto'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Usar imagen de ejemplo'),
                              ),
                              SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Usar iniciales'),
                              ),
                            ],
                          ),
                        );
                        if (mounted && opcion != null)
                          setState(() => _foto = opcion);
                      },
                      child: const Text('Cambiar foto'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _campo(_nombre, 'Nombre visible'),
                const SizedBox(height: 14),
                _campo(_bio, 'Sobre mí', minimo: 0, maxLines: 3),
                const SizedBox(height: 14),
                _bloque('Distrito asociado', widget.datos.zona),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _guardando
                      ? null
                      : () async {
                          if (!_form.currentState!.validate()) return;
                          setState(() => _guardando = true);
                          await widget.datos.guardarPerfil(
                            _nombre.text.trim(),
                            _bio.text.trim(),
                            _foto,
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      );
}

void _abrirPublicacion(
  BuildContext context,
  _DatosBarrio datos,
  _Publicacion item,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => AnimatedBuilder(
        animation: datos,
        builder: (context, _) {
          final accion = switch ((item.tipo, item.estado)) {
            ('Ayuda', 'Abierta') => ('Ofrecer ayuda', 'En coordinación'),
            ('Ayuda', 'En coordinación') => ('Marcar completada', 'Completada'),
            ('Misión', '2 de 3 pasos') => ('Completar misión', 'Completada'),
            ('Anuncio', 'Inscripciones abiertas') => (
                'Quiero participar',
                'Participación registrada',
              ),
            _ => null,
          };
          return Scaffold(
            appBar: AppBar(title: Text(item.tipo), backgroundColor: cream),
            body: _contenido(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _bloque(item.titulo, '${item.descripcion}\n${item.estado}'),
                  if (accion != null) ...[
                    const SizedBox(height: 16),
                    _accion(accion.$1, () => datos.actualizar(item, accion.$2)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _Publicar extends StatefulWidget {
  const _Publicar(this.datos, {this.tipo = 'Anuncio'});
  final _DatosBarrio datos;
  final String tipo;
  @override
  State<_Publicar> createState() => _PublicarState();
}

class _PublicarState extends State<_Publicar> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController(),
      _descripcion = TextEditingController();
  late String _tipo = widget.tipo;

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Publicar'), backgroundColor: cream),
        body: _contenido(
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de publicación',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final s in ['Anuncio', 'Negocio', 'Ayuda'])
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (s) {
                    if (s != null) setState(() => _tipo = s);
                  },
                ),
                const SizedBox(height: 14),
                _campo(_titulo, 'Título'),
                const SizedBox(height: 14),
                _campo(_descripcion, 'Descripción', maxLines: 3),
                const SizedBox(height: 14),
                _accion('Publicar en mi barrio', () {
                  if (!_form.currentState!.validate()) return;
                  final estado = switch (_tipo) {
                    'Ayuda' => 'Abierta',
                    'Anuncio' => 'Inscripciones abiertas',
                    _ => 'Publicado',
                  };
                  widget.datos.publicar(
                    _Publicacion(
                      _tipo,
                      _titulo.text.trim(),
                      _descripcion.text.trim(),
                      estado,
                    ),
                  );
                  Navigator.pop(context);
                }),
              ],
            ),
          ),
        ),
      );
}

class _ModuloBarrio extends StatefulWidget {
  const _ModuloBarrio(this.datos, this.indice);
  final _DatosBarrio datos;
  final int indice;
  @override
  State<_ModuloBarrio> createState() => _ModuloBarrioState();
}

class _ModuloBarrioState extends State<_ModuloBarrio> {
  final revisados = <String>{};
  static const titulos = [
    'Servicios de oficios',
    'Muro de favores',
    'Eventos del barrio',
    'Misiones y grupos',
    'Mochila de emergencia',
    'Noticias y alertas',
    'Mapa',
    'Mensajes',
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.datos,
        builder: (context, _) {
          final i = widget.indice, datos = widget.datos;
          final tipo = switch (i) {
            0 => 'Negocio',
            1 => 'Ayuda',
            2 || 5 => 'Anuncio',
            3 => 'Misión',
            _ => null,
          };
          return Scaffold(
            appBar: AppBar(title: Text(titulos[i]), backgroundColor: cream),
            body: _contenido(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  label(datos.zona, 15, color: muted),
                  const SizedBox(height: 14),
                  if (tipo != null) ...[
                    for (final item in datos.publicaciones.where(
                      (p) => p.tipo == tipo,
                    )) ...[
                      _bloque(
                        item.titulo,
                        '${item.descripcion}\n${item.estado}',
                        onTap: () => _abrirPublicacion(context, datos, item),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (i <= 2)
                      _accion(
                        'Nueva publicación',
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _Publicar(datos, tipo: tipo),
                          ),
                        ),
                      ),
                  ],
                  if (i == 4) ...[
                    label('Revisa tus suministros', 19, bold: true),
                    for (final item in [
                      'Agua',
                      'Linterna',
                      'Botiquín',
                      'Radio portátil',
                    ])
                      CheckboxListTile(
                        value: revisados.contains(item),
                        title: Text(item),
                        onChanged: (value) => setState(() {
                          if (value == true) {
                            revisados.add(item);
                          } else {
                            revisados.remove(item);
                          }
                        }),
                      ),
                  ],
                  if (i == 6)
                    _bloque(
                      'Zona del barrio',
                      'Distrito elegido: ${datos.distrito}. Vista de ejemplo sin mapa en tiempo real.',
                    ),
                  if (i == 7)
                    _bloque(
                      'Coordinación vecinal',
                      'Aquí aparecerán las conversaciones del barrio cuando se conecte el servicio de mensajería.',
                    ),
                ],
              ),
            ),
          );
        },
      );
}
