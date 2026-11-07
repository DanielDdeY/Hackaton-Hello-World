// ignore_for_file: curly_braces_in_flow_control_structures, prefer_collection_literals

part of 'home.dart';

class _DatosBarrio extends ChangeNotifier {
  _DatosBarrio(
    this.preferencias,
    this.departamento,
    this.provincia,
    this.distrito,
    this.nombre,
    this.bio,
    this.foto,
  );

  final SharedPreferences preferencias;
  final String departamento, provincia, distrito;
  String nombre, bio;
  bool foto;
  int favores = 4;
  int puntos = 1250;
  String get zona => [distrito, provincia, departamento].toSet().join(', ');
  String get iniciales => nombre
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((p) => p.isEmpty ? '' : p.substring(0, 1).toUpperCase())
      .join();

  Future<void> guardarPerfil(
    String nuevoNombre,
    String nuevaBio,
    bool nuevaFoto,
  ) async {
    nombre = nuevoNombre;
    bio = nuevaBio;
    foto = nuevaFoto;
    notifyListeners();
    try {
      await preferencias.setString('vecino_nombre', nombre);
      await preferencias.setString('vecino_bio', bio);
      await preferencias.setBool('vecino_foto_demo', foto);
    } catch (e) {
      debugPrint('No se pudo guardar el perfil: $e');
    }
  }

}

class _Entrada extends StatefulWidget {
  const _Entrada({this.onAuthenticated});

  final VoidCallback? onAuthenticated;

  @override
  State<_Entrada> createState() => _EntradaState();
}

class _EntradaState extends State<_Entrada> {
  late SharedPreferences _prefs;
  final _celular = TextEditingController();
  final _codigo = TextEditingController();
  final _departamento = TextEditingController();
  final _provincia = TextEditingController();
  final _distrito = TextEditingController();
  final _form = GlobalKey<FormState>();
  _DatosBarrio? _datos;
  int _paso = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    _DatosBarrio? datos;
    try {
      _prefs = await SharedPreferences.getInstance();
      final d = _prefs.getString('vecino_distrito');
      if (d != null) {
        datos = _DatosBarrio(
          _prefs,
          _prefs.getString('vecino_departamento') ?? '',
          _prefs.getString('vecino_provincia') ?? '',
          d,
          _prefs.getString('vecino_nombre') ?? 'Carlos Mendoza',
          _prefs.getString('vecino_bio') ??
              'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
          _prefs.getBool('vecino_foto_demo') ?? false,
        );
      }
    } catch (e) {
      debugPrint('No se pudo cargar el perfil: $e');
    }
    if (mounted)
      setState(() {
        _datos = datos;
        _cargando = false;
      });
    if (mounted && datos != null) widget.onAuthenticated?.call();
  }

  @override
  void dispose() {
    for (final c in [_celular, _codigo, _departamento, _provincia, _distrito]) {
      c.dispose();
    }
    _datos?.dispose();
    super.dispose();
  }

  void _ir(int paso) => setState(() => _paso = paso);

  Future<void> _confirmar() async {
    final dep = _departamento.text.trim();
    final prov = _provincia.text.trim();
    final dist = _distrito.text.trim();
    setState(
      () => _datos = _DatosBarrio(
        _prefs,
        dep,
        prov,
        dist,
        'Carlos Mendoza',
        'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
        false,
      ),
    );
    try {
      await _prefs.setString('vecino_departamento', dep);
      await _prefs.setString('vecino_provincia', prov);
      await _prefs.setString('vecino_distrito', dist);
    } catch (e) {
      debugPrint('No se pudo guardar el distrito: $e');
    }
    if (mounted) widget.onAuthenticated?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_datos case final datos?) return Inicio(datos: datos);
    const titulos = [
      '¡Hola, vecino!',
      'Ingresa tu celular',
      'Revisa tus mensajes',
      '¿Dónde está tu barrio?',
      'Confirma tu barrio',
    ];
    final contenido = switch (_paso) {
      0 => <Widget>[
          label(
            'Encuentra oficios, pide una mano y conoce a tu comunidad, estés donde estés en el Perú.',
            17,
            color: muted,
          ),
          tarjeta(
            radius: 18,
            color: const Color(0xfffbe1c4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  icono('Firulais', 61),
                  const SizedBox(width: 12),
                  Expanded(
                    child:
                        label('¡Vamos a encontrar tu barrio!', 19, bold: true),
                  ),
                ],
              ),
            ),
          ),
          _accion('Continuar con celular', () => _ir(1)),
          OutlinedButton(
            onPressed: () => _ir(3),
            child: const Text('Continuar con Google · demo'),
          ),
        ],
      1 => <Widget>[
          label(
            'En la app conectada recibirías un código por SMS. Aquí puedes probar el recorrido.',
            16,
            color: muted,
          ),
          _campo(
            _celular,
            'Número de celular',
            tipo: TextInputType.phone,
            prefijo: '+51 ',
            minimo: 9,
            soloDigitos: true,
          ),
          _accion('Continuar con código de prueba', () {
            if (_form.currentState!.validate()) _ir(2);
          }),
        ],
      2 => <Widget>[
          label(
            'Para esta demostración, escribe el código 123456.',
            16,
            color: muted,
          ),
          _campo(
            _codigo,
            'Código de 6 dígitos',
            tipo: TextInputType.number,
            minimo: 6,
            soloDigitos: true,
            esperado: '123456',
          ),
          _accion('Verificar y continuar', () {
            if (_form.currentState!.validate()) _ir(3);
          }),
        ],
      3 => <Widget>[
          label(
            'Escribe la zona donde quieres participar. Puedes registrar cualquier distrito del Perú.',
            16,
            color: muted,
          ),
          _campo(_departamento, 'Departamento'),
          _campo(_provincia, 'Provincia'),
          _campo(_distrito, 'Distrito'),
          _accion('Revisar distrito', () {
            if (_form.currentState!.validate()) _ir(4);
          }),
        ],
      _ => <Widget>[
          _bloque(
            'Distrito seleccionado',
            '${_distrito.text.trim()}\n${_provincia.text.trim()} · ${_departamento.text.trim()}',
          ),
          _accion('Confirmar y conocer la app', _confirmar),
          OutlinedButton(
            onPressed: () => _ir(3),
            child: const Text('Elegir otro distrito'),
          ),
        ],
    };
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text('Mi Barrio'),
        leading:
            _paso == 0 ? null : BackButton(onPressed: () => _ir(_paso - 1)),
      ),
      body: _contenido(
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              label(titulos[_paso], 29, bold: true),
              for (final widget in contenido) ...[
                const SizedBox(height: 16),
                widget,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget _campo(
  TextEditingController controller,
  String titulo, {
  int minimo = 1,
  TextInputType? tipo,
  String? prefijo,
  bool soloDigitos = false,
  String? esperado,
  int maxLines = 1,
}) =>
    TextFormField(
      controller: controller,
      keyboardType: tipo,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: titulo,
        prefixText: prefijo,
        filled: true,
        fillColor: paper,
        border: const OutlineInputBorder(),
      ),
      validator: (texto) {
        final s = texto?.trim() ?? '';
        if (soloDigitos && !RegExp(r'^[0-9]+$').hasMatch(s))
          return 'Escribe solo números.';
        if (soloDigitos && s.length != minimo)
          return 'Escribe $minimo dígitos.';
        if (s.length < minimo) return 'Completa este campo.';
        if (esperado != null && s != esperado)
          return 'Revisa el código de prueba.';
        return null;
      },
    );

Widget _accion(String titulo, VoidCallback onPressed) => FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: orange,
        minimumSize: const Size(0, 50),
      ),
      child: Text(titulo),
    );

Widget _contenido(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(padding: const EdgeInsets.all(22), children: [child]),
      ),
    );

Widget _bloque(String titulo, String descripcion, {VoidCallback? onTap}) =>
    tarjeta(
      radius: 16,
      border: true,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label(titulo, 17, bold: true),
            const SizedBox(height: 7),
            label(descripcion, 14, color: muted),
          ],
        ),
      ),
    );
