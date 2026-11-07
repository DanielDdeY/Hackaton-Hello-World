// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/create_post/domain/services/auth_gateway.dart';
import 'peru_locations.dart';
import 'user_profile.dart';

part 'login.dart';
part 'tutorial.dart';

const cream = Color(0xfffafafa);
const paper = Color(0xffffffff);
const ink = Color(0xff1a1a1a);
const muted = Color(0xff5c5c5c);
const line = Color(0xffd9d9d9);
const orange = Color(0xff006d77);

class MiBarrioHome extends StatelessWidget {
  const MiBarrioHome({super.key, this.homeOnly = false, this.onAuthenticated});

  final bool homeOnly;
  final VoidCallback? onAuthenticated;

  @override
  Widget build(BuildContext context) {
    if (homeOnly) return const _InicioLoader();
    return _Entrada(onAuthenticated: onAuthenticated);
  }
}

class _InicioLoader extends StatefulWidget {
  const _InicioLoader();

  @override
  State<_InicioLoader> createState() => _InicioLoaderState();
}

class _InicioLoaderState extends State<_InicioLoader> {
  late final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();

  @override
  Widget build(BuildContext context) => FutureBuilder<SharedPreferences>(
    future: _preferences,
    builder: (context, snapshot) {
      final preferences = snapshot.data;
      if (preferences == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return _InicioProfileLoader(preferences);
    },
  );
}

class _InicioProfileLoader extends StatelessWidget {
  const _InicioProfileLoader(this.preferences);

  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthGateway?>();
    final store = context.read<UserProfileStore?>();
    final fallback = UserProfile(
      name: preferences.getString('vecino_nombre') ?? 'Carlos Mendoza',
      phoneNumber: preferences.getString('vecino_telefono') ?? '',
      role: preferences.getString('vecino_rol') ?? 'Vecino',
      bio: preferences.getString('vecino_bio') ?? 'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
      department: preferences.getString('vecino_departamento') ?? '',
      province: preferences.getString('vecino_provincia') ?? '',
      district: preferences.getString('vecino_distrito') ?? '',
      xp: preferences.getInt('vecino_xp') ?? 0,
      stars: preferences.getInt('vecino_stars') ?? 0,
      favors: preferences.getInt('vecino_favores') ?? 0,
      tools: preferences.getInt('vecino_herramientas') ?? 0,
      petHunger: preferences.getDouble('vecino_hambre') ?? 0,
    );
    if (store == null || auth?.currentUid == null) {
      return Inicio(datos: _DatosBarrio(preferences, fallback));
    }
    return FutureBuilder<UserProfile?>(
      future: store.load(
        auth!.currentUid!,
        fallbackName: fallback.name,
        fallbackBio: fallback.bio,
        fallbackDepartment: fallback.department,
        fallbackProvince: fallback.province,
        fallbackDistrict: fallback.district,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snapshot.data ?? fallback;
        if (snapshot.hasError) {
          debugPrint(
            'No se pudo cargar el perfil de Firestore: ${snapshot.error}',
          );
        }
        return Inicio(datos: _DatosBarrio(preferences, profile));
      },
    );
  }
}

class Inicio extends StatefulWidget {
  const Inicio({super.key, required this.datos});
  final _DatosBarrio datos;

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  late double hambre = widget.datos.hambre;

  static const _claveTutorial = 'tutorial_inicio_v1_visto';
  final _inicio = GlobalKey();
  final _perfilTutorial = GlobalKey();
  final _sosTutorial = GlobalKey();
  final _campanaTutorial = GlobalKey();
  final _wrappedTutorial = GlobalKey();
  final _mascotaTutorial = GlobalKey();
  final _filasTutorial = List.generate(3, (_) => GlobalKey());
  int? _pasoTutorial;
  List<Rect> _zonasTutorial = [];
  int _solicitudTutorial = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrirSiEsNuevo());
  }

  Future<void> _abrirSiEsNuevo() async {
    var visto = false;
    try {
      final preferencias = await SharedPreferences.getInstance();
      visto = preferencias.getBool(_claveTutorial) ?? false;
    } catch (error) {
      debugPrint('No se pudo leer la preferencia del tutorial: $error');
    }
    if (mounted && !visto && _solicitudTutorial == 0) {
      await _mostrarPaso(0);
    }
  }

  Future<void> _mostrarPaso(int paso) async {
    final destinos = [
      [_perfilTutorial],
      [_campanaTutorial, _sosTutorial],
      [_wrappedTutorial],
      [_mascotaTutorial],
      [_filasTutorial[0]],
      [_filasTutorial[1]],
      [_filasTutorial[2]],
      [_filasTutorial[2]],
    ][paso];
    final solicitud = ++_solicitudTutorial;
    final destino = destinos.first.currentContext;
    if (destino != null && paso != _pasos.length - 1) {
      await Scrollable.ensureVisible(destino, alignment: paso < 2 ? 0 : .35);
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || solicitud != _solicitudTutorial) return;

    final raiz = _inicio.currentContext?.findRenderObject();
    if (raiz is! RenderBox || !raiz.hasSize) return;
    final zonas = <Rect>[];
    for (final key in destinos) {
      final caja = key.currentContext?.findRenderObject();
      if (caja is RenderBox && caja.hasSize) {
        final origen = caja.localToGlobal(Offset.zero, ancestor: raiz);
        final rect = (origen & caja.size)
            .inflate(5)
            .intersect(Offset.zero & raiz.size);
        if (!rect.isEmpty) zonas.add(rect);
      }
    }
    setState(() {
      _pasoTutorial = paso;
      _zonasTutorial = zonas;
    });
  }

  Future<void> _cerrarTutorial() async {
    _solicitudTutorial++;
    setState(() => _pasoTutorial = null);
    try {
      final preferencias = await SharedPreferences.getInstance();
      preferencias.setBool(_claveTutorial, true);
    } catch (error) {
      debugPrint('No se pudo guardar la preferencia del tutorial: $error');
    }
  }

  static const accesos = [
    (
      'Servicios\nde oficios',
      'ServiciosDeOficios',
      Color(0xfffbe5cf),
      'Gasfitería, electricidad y otros oficios recomendados por tus vecinos.',
    ),
    (
      'Muro de\nfavores',
      'MuroDeFavores',
      Color(0xfffce4df),
      'Pide una herramienta prestada u ofrece ayuda a un vecino.',
    ),
    (
      'Eventos\ndel barrio',
      'EventosDelBarrio',
      Color(0xffe4e9d5),
      'Consulta reuniones, simulacros y actividades comunitarias.',
    ),
    (
      'Misiones\ny grupos',
      'MisionesYGrupos',
      Color(0xffe5e2f5),
      'Completa acciones de ayuda para sumar Aura.',
    ),
    (
      'Mochila de\nemergencia',
      'MochilaDeEmergencia',
      Color(0xfff5e2cd),
      'Revisa los suministros de tu vivienda.',
    ),
    (
      'Noticias\ny alertas',
      'NoticiasYAlertas',
      Color(0xffffe5ad),
      'Consulta los avisos de tu grupo barrial.',
    ),
  ];

  void detalle(String titulo, String mensaje) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: paper,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label(titulo, 21, bold: true),
              const SizedBox(height: 10),
              label(mensaje, 15, color: muted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> confirmarSos() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simular alerta SOS'),
        content: const Text(
          'Esta es una demostración del flujo de emergencia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simular'),
          ),
        ],
      ),
    );
    if (confirmado == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Alerta SOS simulada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final paso = _pasoTutorial;
    return PopScope(
      canPop: paso == null,
      onPopInvokedWithResult: (salio, resultado) {
        if (!salio && paso != null) {
          paso == 0 ? _cerrarTutorial() : _mostrarPaso(paso - 1);
        }
      },
      child: Stack(
        key: _inicio,
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            excluding: paso != null,
            child: AnimatedBuilder(
              animation: widget.datos,
              builder: (context, child) => _pantallaInicio(),
            ),
          ),
          if (paso != null)
            _TutorialInicio(
              paso: paso,
              zonas: _zonasTutorial,
              siguiente: () => _mostrarPaso(paso + 1),
              atras: () => _mostrarPaso(paso - 1),
              cerrar: _cerrarTutorial,
            ),
        ],
      ),
    );
  }

  Widget _pantallaInicio() => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _encabezado(),
                const SizedBox(height: 12),
                _perfil(),
                const SizedBox(height: 12),
                _wrapped(),
                const SizedBox(height: 12),
                _mascota(),
                const SizedBox(height: 12),
                for (var index = 0; index < accesos.length; index += 2) ...[
                  if (index > 0) const SizedBox(height: 10),
                  Row(
                    key: _filasTutorial[index ~/ 2],
                    children: [
                      Expanded(child: _acceso(index)),
                      const SizedBox(width: 10),
                      Expanded(child: _acceso(index + 1)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _encabezado() => SizedBox(
    height: 28,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        label('MI BARRIO', 13, bold: true, color: orange),
        InkWell(
          key: _campanaTutorial,
          onTap: () => detalle(
            'Notificaciones',
            'Aquí aparecerán los avisos de tu grupo.',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: icono('Notificaciones', 22),
          ),
        ),
      ],
    ),
  );

  Widget _perfil() => SizedBox(
    height: 91,
    child: Row(
      children: [
        _avatarVecino(widget.datos.iniciales, widget.datos.foto, 29),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            key: _perfilTutorial,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label(widget.datos.nombre, 19, bold: true),
              const SizedBox(height: 5),
              label(widget.datos.rol, 12, color: muted),
              const SizedBox(height: 5),
              label(
                '★ Nivel ${widget.datos.nivel}   ·   XP: ${widget.datos.xp}   ·   Star: ${widget.datos.stars}',
                12,
                bold: true,
                color: orange,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        tarjeta(
          color: const Color(0xffb72f29),
          radius: 15,
          onTap: confirmarSos,
          child: SizedBox(
            key: _sosTutorial,
            width: 82,
            height: 66,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  label('¡SOS!', 21, bold: true, color: Colors.white),
                  const SizedBox(height: 3),
                  label('EMERGENCIA', 9, bold: true, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _wrapped() => tarjeta(
    color: const Color(0xfff6dfec),
    radius: 18,
    onTap: () => detalle(
      'Tu Wrapped del mes',
      'Este mes completaste ${widget.datos.favores} favores y prestaste ${widget.datos.herramientas} herramientas.',
    ),
    child: SizedBox(
      key: _wrappedTutorial,
      height: 79,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            icono('Regalo', 36),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label('Tu Wrapped del mes', 17, bold: true),
                    const SizedBox(height: 5),
                    label('Descubre tu impacto en el barrio', 12, color: muted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _alimentarMascota() async {
    final nuevaHambre = (hambre - .20).clamp(0.0, 1.0).toDouble();
    setState(() => hambre = nuevaHambre);
    widget.datos.hambre = nuevaHambre;
    final auth = context.read<AuthGateway?>();
    final store = context.read<UserProfileStore?>();
    final uid = auth?.currentUid;
    if (store != null && uid != null) {
      try {
        await store.save(uid, widget.datos.toProfile());
      } catch (error) {
        debugPrint('No se pudo guardar el estado de la mascota: $error');
      }
    }
  }

  Widget _mascota() => tarjeta(
    radius: 18,
    border: true,
    child: SizedBox(
      key: _mascotaTutorial,
      height: 139,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 78,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xfffbe8d1),
                borderRadius: BorderRadius.circular(19),
              ),
              alignment: Alignment.center,
              child: widget.datos.mascotaDesbloqueada
                  ? icono('Firulais', 61)
                  : const Icon(Icons.lock_outline, size: 38, color: muted),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label(
                    widget.datos.mascotaDesbloqueada
                        ? 'Firulais'
                        : 'Mascota bloqueada',
                    17,
                    bold: true,
                  ),
                  const SizedBox(height: 7),
                  if (widget.datos.mascotaDesbloqueada) ...[
                    label('Mascota comunitaria · Hambre', 11, color: muted),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: hambre,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: const Color(0xffefdfca),
                      color: const Color(0xffc96631),
                    ),
                    const SizedBox(height: 7),
                    tarjeta(
                      color: const Color(0xfffbe1c4),
                      radius: 12,
                      onTap: hambre == 0 ? null : _alimentarMascota,
                      child: SizedBox(
                        width: 186,
                        height: 33,
                        child: Center(
                          child: label(
                            hambre == 0
                                ? 'Firulais está satisfecho'
                                : 'Alimentar',
                            12,
                            bold: true,
                            color: orange,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    label(
                      'Alcanza el nivel 25 para desbloquearla',
                      12,
                      color: muted,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _acceso(int index) {
    final (titulo, asset, tono, _) = accesos[index];
    return tarjeta(
      color: index == 5 ? const Color(0xfffff1d0) : paper,
      radius: 16,
      border: true,
      onTap: () => detalle(titulo.replaceAll('\n', ' '), accesos[index].$4),
      child: SizedBox(
        height: 78,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tono,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: icono(asset, 24),
              ),
              const SizedBox(width: 9),
              Expanded(child: label(titulo, 13, bold: true)),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _avatarVecino(String iniciales, bool foto, double radio) => CircleAvatar(
  radius: radio,
  backgroundColor: foto ? const Color(0xffe0eeee) : const Color(0xffd7eeee),
  child: foto
      ? Icon(Icons.person, size: radio, color: orange)
      : label(iniciales, radio * .57, bold: true, color: orange),
);

Widget label(
  String value,
  double size, {
  bool bold = false,
  Color color = ink,
}) => Text(
  value,
  style: TextStyle(
    fontSize: size,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    color: color,
  ),
);

Widget icono(String asset, double size) => SvgPicture.asset(
  'assets/$asset.svg',
  width: size,
  height: size,
  excludeFromSemantics: true,
);

Widget tarjeta({
  required Widget child,
  required double radius,
  Color color = paper,
  bool border = false,
  VoidCallback? onTap,
}) => Material(
  color: color,
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: border ? const BorderSide(color: line) : BorderSide.none,
  ),
  child: InkWell(onTap: onTap, child: child),
);
