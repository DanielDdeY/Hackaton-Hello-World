// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/create_post/domain/services/auth_gateway.dart';
import '../features/create_post/domain/services/photo_picker.dart';
import '../features/create_post/presentation/forms/emergency/emergency_form.dart';
import '../features/economy/domain/models/app_user.dart';
import '../features/economy/domain/repositories/user_repository.dart';
import '../features/economy/domain/services/period_provider.dart';
import '../features/emergency/data/firebase_emergency_alert_repository.dart';
import '../features/emergency/data/firebase_emergency_post_repository.dart';
import '../features/emergency/data/sos_consent_store.dart';
import '../features/emergency/domain/emergency_alert.dart';
import '../features/emergency/presentation/sos_alert_banner.dart';
import '../features/emergency/presentation/sos_confirmation_sheet.dart';
import 'peru_locations.dart';
import 'user_profile.dart';
import '../features/economia/domain/entities/nivel_xp.dart';
import '../features/mascota/data/repositories/local_mascota_repository.dart';
import '../features/mascota/presentation/pages/mascota_page.dart';

part 'login.dart';
part 'mi_perfil.dart';
part 'tutorial.dart';

const cream = Color(0xfffafafa);
const paper = Color(0xffffffff);
const ink = Color(0xff1a1a1a);
const muted = Color(0xff5c5c5c);
const line = Color(0xffd9d9d9);
const orange = Color(0xff006d77);

class _EditarInformacionPage extends StatefulWidget {
  const _EditarInformacionPage({required this.datos});

  final _DatosBarrio datos;

  @override
  State<_EditarInformacionPage> createState() => _EditarInformacionPageState();
}

class _EditarInformacionPageState extends State<_EditarInformacionPage> {
  late final TextEditingController _nombre;
  late final TextEditingController _bio;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.datos.nombre);
    _bio = TextEditingController(text: widget.datos.bio);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty || _guardando) return;

    setState(() => _guardando = true);
    final auth = context.read<AuthGateway?>();
    final store = context.read<UserProfileStore?>();
    try {
      await widget.datos.guardarPerfil(
        nombre,
        _bio.text.trim(),
        widget.datos.foto,
      );
      final uid = auth?.currentUid;
      if (store != null && uid != null) {
        await store.save(uid, widget.datos.toProfile());
      }
      if (mounted) Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      debugPrint('No se pudo actualizar el perfil: ${error.code}');
      _mostrarError();
    } catch (error) {
      debugPrint('No se pudo actualizar el perfil: $error');
      _mostrarError();
    }
  }

  void _mostrarError() {
    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo actualizar la información.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Editar información'),
      actions: [
        TextButton(
          onPressed: _guardando ? null : _guardar,
          child: const Text('Guardar'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Actualiza la información que verán tus vecinos.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _bio,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Biografía / Sobre ti',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Card(
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
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Color(0xFF006D77)),
                    SizedBox(width: 8),
                    Text(
                      'Información comunitaria',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF006D77),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Distrito: ${widget.datos.distrito.isEmpty ? "Ate" : widget.datos.distrito}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zona: ${widget.datos.zona.isEmpty ? "Ate, Lima, Lima" : widget.datos.zona}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (widget.datos.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Teléfono: ${widget.datos.phoneNumber}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Progreso: Nivel ${widget.datos.nivel} · ${widget.datos.xp} XP (${widget.datos.weeklyXp} XP este mes)',
                  style: const TextStyle(fontSize: 12),
                ),
                if (widget.datos.insignias.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.datos.insignias.map((insignia) {
                      return Chip(
                        label: Text(
                          insignia,
                          style: const TextStyle(fontSize: 10),
                        ),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFFFFF3D6),
                        side: const BorderSide(color: Color(0xFFFFD54F)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.save_outlined),
          label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
        ),
      ],
    ),
  );
}

class MiBarrioHome extends StatelessWidget {
  const MiBarrioHome({
    super.key,
    this.homeOnly = false,
    this.onAuthenticated,
    this.onSignedOut,
    this.onOpenMap,
  });

  final bool homeOnly;
  final VoidCallback? onAuthenticated;
  final VoidCallback? onSignedOut;
  final void Function(LatLng? location)? onOpenMap;

  @override
  Widget build(BuildContext context) {
    if (homeOnly) {
      return _InicioLoader(onSignedOut: onSignedOut, onOpenMap: onOpenMap);
    }
    return _Entrada(onAuthenticated: onAuthenticated);
  }
}

class _InicioLoader extends StatefulWidget {
  const _InicioLoader({this.onSignedOut, this.onOpenMap});

  final VoidCallback? onSignedOut;
  final void Function(LatLng? location)? onOpenMap;

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
      return _InicioProfileLoader(
        preferences,
        onSignedOut: widget.onSignedOut,
        onOpenMap: widget.onOpenMap,
      );
    },
  );
}

class _InicioProfileLoader extends StatelessWidget {
  const _InicioProfileLoader(
    this.preferences, {
    this.onSignedOut,
    this.onOpenMap,
  });

  final SharedPreferences preferences;
  final VoidCallback? onSignedOut;
  final void Function(LatLng? location)? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthGateway?>();
    final store = context.read<UserProfileStore?>();
    final fallback = UserProfile(
      name: preferences.getString('vecino_nombre') ?? 'Carlos Mendoza',
      phoneNumber: preferences.getString('vecino_telefono') ?? '',
      bio:
      preferences.getString('vecino_bio') ??
          'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
      department: preferences.getString('vecino_departamento') ?? '',
      province: preferences.getString('vecino_provincia') ?? '',
      district: preferences.getString('vecino_distrito') ?? '',
      xp: preferences.getInt('vecino_xp') ?? 0,
      weeklyXp: preferences.getInt('vecino_xp_semana') ?? 0,
      stars: preferences.getInt('vecino_stars') ?? 0,
      favors: preferences.getInt('vecino_favores') ?? 0,
      tools: preferences.getInt('vecino_herramientas') ?? 0,
      petHunger: preferences.getDouble('vecino_hambre') ?? 0,
      favoresCompletados: preferences.getInt('vecino_favores_completados') ?? 0,
      eventosAsistidos: preferences.getInt('vecino_eventos') ?? 0,
      reconocimientos: preferences.getInt('vecino_reconocimientos') ?? 0,
      rachaSemanal: preferences.getInt('vecino_racha') ?? 0,
      badges: preferences.getStringList('vecino_insignias') ?? const [],
    );
    if (store == null || auth?.currentUid == null) {
      return Inicio(
        datos: _DatosBarrio(preferences, fallback),
        onSignedOut: onSignedOut,
        onOpenMap: onOpenMap,
      );
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
        return Inicio(
          datos: _DatosBarrio(preferences, profile),
          onSignedOut: onSignedOut,
          onOpenMap: onOpenMap,
        );
      },
    );
  }
}

class Inicio extends StatefulWidget {
  const Inicio({
    super.key,
    required this.datos,
    this.onSignedOut,
    this.onOpenMap,
  });
  final _DatosBarrio datos;
  final VoidCallback? onSignedOut;
  final void Function(LatLng? location)? onOpenMap;

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  late double hambre = widget.datos.hambre;
  StreamSubscription<AppUser>? _statsSubscription;
  SimulatablePeriodProvider? _simulatablePeriod;
  AppUser? _lastRawStats;

  static const _claveTutorial = 'tutorial_inicio_v1_visto';
  final _inicio = GlobalKey();
  final _perfilTutorial = GlobalKey();
  final _sosTutorial = GlobalKey();
  final _campanaTutorial = GlobalKey();
  final _wrappedTutorial = GlobalKey();
  final _mascotaTutorial = GlobalKey();
  static const _sosConsent = SosConsentStore();
  int? _pasoTutorial;
  List<Rect> _zonasTutorial = [];
  int _solicitudTutorial = 0;
  bool _sosSending = false;
  String? _pendingSosId;

  @override
  void initState() {
    super.initState();
    _bindStatsStream();
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrirSiEsNuevo());
  }

  void _bindStatsStream() {
    final auth = context.read<AuthGateway?>();
    final users = context.read<UserRepository?>();
    _simulatablePeriod = context.read<SimulatablePeriodProvider?>();
    _simulatablePeriod?.addListener(_onSimulatedPeriodChanged);
    final uid = auth?.currentUid;
    if (users == null || uid == null || uid.isEmpty) return;
    _statsSubscription = users.watchUserStats(uid).listen(
          (user) {
        if (!mounted) return;
        _lastRawStats = user;
        widget.datos.syncEconomy(user);
      },
      onError: (Object error) {
        debugPrint('No se pudo escuchar watchUserStats en Inicio: $error');
      },
    );
  }

  void _onSimulatedPeriodChanged() {
    final last = _lastRawStats;
    final activePeriod = _simulatablePeriod?.currentPeriod;
    if (!mounted || last == null || activePeriod == null) return;
    widget.datos.syncEconomy(
      AppUser(
        uid: last.uid,
        name: last.name,
        district: last.district,
        currentPeriod: activePeriod,
        xpTotal: last.xpTotal,
        monthlyXp: last.monthlyXp,
        rankingPeriod: last.rankingPeriod,
        availableCoins: last.availableCoins,
        averageStars: last.averageStars,
        reviewCount: last.reviewCount,
      ),
    );
  }

  @override
  void dispose() {
    _simulatablePeriod?.removeListener(_onSimulatedPeriodChanged);
    unawaited(_statsSubscription?.cancel());
    super.dispose();
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
      [_mascotaTutorial],
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

  Future<void> _abrirMiPerfil() async {
    Navigator.pop(context);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => _MiPerfilPage(datos: widget.datos)),
    );
  }

  Future<void> _editarInformacion() async {
    Navigator.pop(context);
    final actualizada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _EditarInformacionPage(datos: widget.datos),
      ),
    );
    if (mounted && actualizada == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu información se actualizó.')),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    final auth = context.read<AuthGateway?>();
    try {
      await auth?.signOut();
      final preferences = widget.datos.preferencias;
      for (final key in [
        'vecino_departamento',
        'vecino_provincia',
        'vecino_distrito',
        'vecino_nombre',
        'vecino_telefono',
        'vecino_profile_uid',
        'vecino_bio',
        'vecino_xp',
        'vecino_xp_semana',
        'vecino_stars',
        'vecino_monedas',
        'vecino_favores',
        'vecino_herramientas',
        'vecino_hambre',
        'vecino_favores_completados',
        'vecino_eventos',
        'vecino_reconocimientos',
        'vecino_racha',
        'vecino_insignias',
      ]) {
        await preferences.remove(key);
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onSignedOut?.call();
      }
    } catch (error) {
      debugPrint('No se pudo cerrar sesión: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cerrar sesión.')),
        );
      }
    }
  }

  Widget _drawer() => Drawer(
    child: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(widget.datos.nombre),
            accountEmail: Text(
              widget.datos.distrito.isEmpty ? "Ate" : widget.datos.distrito,
            ),
            currentAccountPicture: _avatarVecino(
              widget.datos.iniciales,
              widget.datos.foto,
              25,
            ),
            decoration: const BoxDecoration(color: orange),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Distrito'),
            subtitle: Text(
              widget.datos.distrito.isEmpty
                  ? 'Ate (Lima)'
                  : '${widget.datos.distrito} (${widget.datos.provincia})',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.leaderboard_outlined),
            title: const Text('Estadísticas y Nivel'),
            subtitle: Row(
              children: [
                Text('Nivel ${widget.datos.nivel} · ${widget.datos.xp} XP · '),
                SvgPicture.asset('assets/ficha.svg', width: 14, height: 14),
                const SizedBox(width: 4),
                Text('${widget.datos.fichas} fichas'),
              ],
            ),
          ),
          if (widget.datos.insignias.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Insignias comunitarias'),
              subtitle: Text(widget.datos.insignias.join(', ')),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi perfil'),
            onTap: _abrirMiPerfil,
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar información'),
            onTap: _editarInformacion,
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Aviso de responsabilidad SOS'),
            subtitle: Text(
              _sosConsent.hasConsent(widget.datos.preferencias)
                  ? 'Aceptado · toca para reiniciar'
                  : 'Pendiente',
            ),
            onTap: _reiniciarAvisoSos,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: _cerrarSesion,
          ),
        ],
      ),
    ),
  );

  Future<void> _abrirAvisoSos() async {
    if (_sosSending) return;
    final preferences = widget.datos.preferencias;
    if (!_sosConsent.hasConsent(preferences)) {
      final accepted = await confirmSosActivation(context);
      if (!accepted || !mounted) return;
      await _sosConsent.grant(preferences);
    }
    if (mounted) await confirmarSos();
  }

  Future<void> _reiniciarAvisoSos() async {
    Navigator.pop(context);
    await _sosConsent.reset(widget.datos.preferencias);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El aviso de responsabilidad SOS se mostrará de nuevo.'),
      ),
    );
  }

  Future<void> confirmarSos() async {
    if (_sosSending) return;
    setState(() => _sosSending = true);
    var sosStage = 'ubicación GPS';
    try {
      final preferences = widget.datos.preferencias;
      final auth = context.read<AuthGateway?>();
      final photoPicker = context.read<PhotoPicker>();
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Activa el GPS para enviar una alerta SOS.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Se necesita permiso de ubicación para enviar SOS.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      sosStage = 'autenticación';
      if (auth == null) {
        throw StateError('No se pudo iniciar sesión para enviar el SOS.');
      }
      final uid = await auth.ensureSignedIn();
      final localCommunityId = widget.datos.distrito.trim().toLowerCase();
      sosStage = 'lectura del perfil de comunidad';
      final profileRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final profile = await profileRef.get();
      final savedCommunityId = profile.data()?['communityId'] as String? ?? '';
      final communityId = savedCommunityId.trim().isNotEmpty
          ? savedCommunityId.trim()
          : localCommunityId;
      if (communityId.isEmpty) {
        throw StateError(
          'Completa tu distrito en el perfil antes de activar el SOS.',
        );
      }
      if (savedCommunityId.trim().isEmpty) {
        sosStage = 'guardado del distrito en tu perfil';
        await profileRef.set({
          'communityId': communityId,
        }, SetOptions(merge: true));
      }

      final alertId =
          _pendingSosId ??
              preferences.getString('sos_pending_alert_id') ??
              FirebaseFirestore.instance.collection('emergency_alerts').doc().id;
      _pendingSosId = alertId;
      await preferences.setString('sos_pending_alert_id', alertId);
      final alertRepository = FirebaseEmergencyAlertRepository();
      sosStage = 'creación de la alerta SOS';
      await alertRepository.create(
        alertId: alertId,
        reporterUid: uid,
        latitude: position.latitude,
        longitude: position.longitude,
        communityId: communityId,
      );

      sosStage = 'formulario de emergencia';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xffb71c1c),
          content: Text('SOS activo. Describe la emergencia.'),
        ),
      );
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EmergencyForm(
            sosAlertId: alertId,
            sosRepository: FirebaseEmergencyPostRepository(
              alertId: alertId,
              photoPicker: photoPicker,
              firestore: FirebaseFirestore.instance,
              storage: FirebaseStorage.instance,
            ),
          ),
        ),
      );

      if (!mounted) return;
      sosStage = 'verificación de la publicación SOS';
      final post = await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(alertId)
          .get();
      if (!post.exists) {
        await alertRepository.close(alertId, EmergencyAlertStatus.cancelled);
      }
      _pendingSosId = null;
      await preferences.remove('sos_pending_alert_id');
    } on FirebaseException catch (error) {
      debugPrint(
        'SOS Firebase failure at $sosStage: ${error.code} ${error.message}',
      );
      if (mounted) {
        _showSosError(
          'Firebase rechazó el SOS durante $sosStage (${error.code}).',
        );
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        _showSosError(
          error.reason == AuthFailureReason.anonymousDisabled
              ? 'Activa el proveedor Anónimo en Firebase Console: Authentication > Proveedores de acceso.'
              : 'No se pudo iniciar sesión para enviar el SOS.',
        );
      }
    } on StateError catch (error) {
      if (mounted) _showSosError(error.message.toString());
    } on Exception catch (error) {
      if (mounted) {
        _showSosError('No se pudo activar el SOS. Inténtalo de nuevo. $error');
      }
    } finally {
      if (mounted) setState(() => _sosSending = false);
    }
  }

  void _showSosError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xffb71c1c),
        content: Text(message),
        duration: const Duration(seconds: 6),
      ),
    );
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
    drawer: _drawer(),
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
                SosAlertBanner(onOpenMap: widget.onOpenMap),
                const SizedBox(height: 12),
                _wrapped(),
                const SizedBox(height: 12),
                _mascota(),
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
        Builder(
          builder: (context) => IconButton(
            tooltip: 'Abrir menú',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        label('AYNI VECI', 13, bold: true, color: orange),
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
              label(
                widget.datos.distrito.isEmpty ? "Ate" : widget.datos.distrito,
                12,
                color: muted,
              ),
              const SizedBox(height: 5),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  label(
                    '★ Nivel ${widget.datos.nivel} · XP: ${widget.datos.xp} ·',
                    12,
                    bold: true,
                    color: orange,
                  ),
                  SvgPicture.asset(
                    'assets/ficha.svg',
                    width: 14,
                    height: 14,
                  ),
                  label(
                    '${widget.datos.fichas}',
                    12,
                    bold: true,
                    color: orange,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        tarjeta(
          color: const Color(0xffb72f29),
          radius: 15,
          onTap: _abrirAvisoSos,
          child: SizedBox(
            key: _sosTutorial,
            width: 82,
            height: 66,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _sosSending
                  ? const Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
                  : Column(
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

  void _abrirMascota() {
    final uid = context.read<AuthGateway?>()?.currentUid ?? 'usr_local';
    final repo = LocalMascotaRepository(preferences: widget.datos.preferencias);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MascotaPage(
          uid: uid,
          mascotaRepository: repo,
          fichasActuales: widget.datos.fichas,
          onFichasActualizadas: (nuevasFichas) {
            setState(() {
              widget.datos.fichas = nuevasFichas;
            });
            widget.datos.preferencias.setInt('vecino_fichas', nuevasFichas);
          },
        ),
      ),
    );
  }

  Widget _mascota() {
    final desbloqueada = widget.datos.mascotaDesbloqueada;
    return tarjeta(
      radius: 18,
      border: true,
      onTap: desbloqueada ? _abrirMascota : null,
      child: SizedBox(
        key: _mascotaTutorial,
        height: 125,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 84,
                decoration: BoxDecoration(
                  color: desbloqueada ? const Color(0xfffbe8d1) : const Color(0xfff0f0f0),
                  borderRadius: BorderRadius.circular(19),
                ),
                alignment: Alignment.center,
                child: desbloqueada
                    ? Image.asset(
                        'assets/mascota/cuy-logo.png',
                        width: 58,
                        height: 58,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 40, color: orange),
                      )
                    : const Icon(Icons.lock_outline, size: 36, color: muted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    label(
                      desbloqueada ? 'Mi Cuy' : 'Mascota bloqueada',
                      17,
                      bold: true,
                    ),
                    const SizedBox(height: 5),
                    if (desbloqueada) ...[
                      label('Compañero barrial · Toca para visitarlo', 11, color: muted),
                      const SizedBox(height: 8),
                      tarjeta(
                        color: const Color(0xfffbe1c4),
                        radius: 12,
                        onTap: _abrirMascota,
                        child: SizedBox(
                          width: 160,
                          height: 30,
                          child: Center(
                            child: label(
                              'Visitar a mi Cuy',
                              12,
                              bold: true,
                              color: orange,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      label(
                        'Alcanza el nivel 2 (210 XP) para desbloquear a tu Cuy',
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