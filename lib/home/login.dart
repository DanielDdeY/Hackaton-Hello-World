// ignore_for_file: curly_braces_in_flow_control_structures, prefer_collection_literals

part of 'home.dart';

class _LocationLoginException implements Exception {
  const _LocationLoginException(this.message, {this.canOpenSettings = false});

  final String message;
  final bool canOpenSettings;
}

class _DatosBarrio extends ChangeNotifier {
  _DatosBarrio(this.preferencias, UserProfile profile)
      : departamento = profile.department,
        provincia = profile.province,
        distrito = profile.district,
        nombre = profile.name,
        phoneNumber = profile.phoneNumber,
        bio = profile.bio,
        xp = profile.xp,
        fichas = profile.fichas,
        weeklyXp = profile.weeklyXp,
        stars = profile.stars,
        availableCoins = profile.fichas > 0
            ? profile.fichas
            : (preferencias.getInt('vecino_fichas') ??
                preferencias.getInt('vecino_monedas') ??
                0),
        favores = profile.favors,
        herramientas = profile.tools,
        hambre = profile.petHunger,
        insignias = profile.badges,
        favoresCompletados = profile.favoresCompletados,
        eventosAsistidos = profile.eventosAsistidos,
        reconocimientos = profile.reconocimientos,
        rachaSemanal = profile.rachaSemanal;

  final SharedPreferences preferencias;
  String departamento;
  String provincia;
  String distrito;
  String nombre;
  String phoneNumber;
  String bio;
  int xp;
  int fichas;
  int weeklyXp;
  int stars;
  int availableCoins;
  int favores;
  int herramientas;
  double hambre;
  List<String> insignias;
  int favoresCompletados;
  int eventosAsistidos;
  int reconocimientos;
  int rachaSemanal;
  bool get mascotaDesbloqueada => NivelXp.mascotaDesbloqueada(xp);
  int get nivel => NivelXp.calcularNivel(xp);

  void syncEconomy(AppUser stats) {
    final nuevasEstrellas = stats.reviewCount > 0
        ? stats.averageStars.round()
        : stars;
    final nuevoDistrito = stats.district.trim().isNotEmpty
        ? stats.district.trim()
        : distrito;
    final huboCambios =
        xp != stats.xpTotal ||
            weeklyXp != stats.effectiveMonthlyXp ||
            fichas != stats.availableCoins ||
            availableCoins != stats.availableCoins ||
            stars != nuevasEstrellas ||
            distrito != nuevoDistrito;
    if (!huboCambios) return;

    xp = stats.xpTotal;
    weeklyXp = stats.effectiveMonthlyXp;
    fichas = stats.availableCoins;
    availableCoins = stats.availableCoins;
    stars = nuevasEstrellas;
    distrito = nuevoDistrito;
    notifyListeners();

    unawaited(preferencias.setInt('vecino_xp', xp));
    unawaited(preferencias.setInt('vecino_xp_semana', weeklyXp));
    unawaited(preferencias.setInt('vecino_stars', stars));
    unawaited(preferencias.setInt('vecino_fichas', fichas));
    unawaited(preferencias.setInt('vecino_monedas', availableCoins));
  }
  UserProfile toProfile() => UserProfile(
    name: nombre,
    phoneNumber: phoneNumber,
    bio: bio,
    department: departamento,
    province: provincia,
    district: distrito,
    xp: xp,
    fichas: fichas,
    weeklyXp: weeklyXp,
    stars: stars,
    favors: favores,
    tools: herramientas,
    petHunger: hambre,
    badges: insignias,
    favoresCompletados: favoresCompletados,
    eventosAsistidos: eventosAsistidos,
    reconocimientos: reconocimientos,
    rachaSemanal: rachaSemanal,
  );
  bool foto = false;
  String get zona => [
    distrito,
    provincia,
    departamento,
  ].toSet().where((e) => e.isNotEmpty).join(', ');
  String get iniciales => nombre
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((p) => p.isEmpty ? '' : p.substring(0, 1).toUpperCase())
      .join();

  Future<void> guardarPerfil(
      String nuevoNombre,
      String nuevaBio,
      bool nuevaFoto) async {
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
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _departamento = TextEditingController();
  final _provincia = TextEditingController();
  final _distrito = TextEditingController();
  final _form = GlobalKey<FormState>();
  _DatosBarrio? _datos;
  String? _departamentoSeleccionado;
  String? _provinciaSeleccionada;
  String? _distritoSeleccionado;
  int _paso = 0;
  bool _cargando = true;
  bool _obteniendoUbicacion = false;
  bool _iniciandoGoogle = false;
  bool _registroNuevo = true;
  bool _verificandoTelefono = false;
  String _telefonoVerificado = '';
  UserProfile? _perfilExistente;
  String _nombreAutenticado = 'Carlos Mendoza';
  String? _errorUbicacion;
  VoidCallback? _accionAjustesUbicacion;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  bool _tieneUbicacion(UserProfile profile) =>
      profile.department.isNotEmpty &&
          profile.province.isNotEmpty &&
          profile.district.isNotEmpty;

  Future<void> _guardarPerfilLocal(UserProfile profile) async {
    final uid = context.read<AuthGateway?>()?.currentUid;
    if (uid != null) await _prefs.setString('vecino_profile_uid', uid);
    await _prefs.setString('vecino_departamento', profile.department);
    await _prefs.setString('vecino_provincia', profile.province);
    await _prefs.setString('vecino_distrito', profile.district);
    await _prefs.setString('vecino_nombre', profile.name);
    await _prefs.setString('vecino_telefono', profile.phoneNumber);
  }

  Future<void> _cargar() async {
    _DatosBarrio? datos;
    final auth = context.read<AuthGateway?>();
    final store = context.read<UserProfileStore?>();
    try {
      _prefs = await SharedPreferences.getInstance();
      UserProfile? perfilRemoto;
      if (store != null) {
        try {
          if (auth != null) await auth.ensureSignedIn();
          final currentUid = auth?.currentUid;
          if (currentUid != null) {
            perfilRemoto = await store.load(
              currentUid,
              fallbackName: 'Vecino',
              fallbackBio:
              'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
              fallbackDepartment: '',
              fallbackProvince: '',
              fallbackDistrict: '',
            );
          }
        } catch (error) {
          debugPrint('No se pudo cargar el perfil remoto: $error');
        }
      }
      if (perfilRemoto != null && _tieneUbicacion(perfilRemoto)) {
        datos = _DatosBarrio(_prefs, perfilRemoto);
      }
      final d = _prefs.getString('vecino_distrito');
      final cachedUid = _prefs.getString('vecino_profile_uid');
      if (datos == null &&
          d != null &&
          (auth == null || cachedUid == auth.currentUid && cachedUid != null)) {
        datos = _DatosBarrio(
          _prefs,
          UserProfile(
            department: _prefs.getString('vecino_departamento') ?? '',
            province: _prefs.getString('vecino_provincia') ?? '',
            district: d,
            name: _prefs.getString('vecino_nombre') ?? 'Carlos Mendoza',
            phoneNumber: _prefs.getString('vecino_telefono') ?? '',
            bio:
            _prefs.getString('vecino_bio') ??
                'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
            xp: _prefs.getInt('vecino_xp') ?? 0,
            fichas: _prefs.getInt('vecino_fichas') ?? _prefs.getInt('vecino_stars') ?? 0,
            stars: _prefs.getInt('vecino_stars') ?? 0,
            favors: _prefs.getInt('vecino_favores') ?? 0,
            tools: _prefs.getInt('vecino_herramientas') ?? 0,
            petHunger: _prefs.getDouble('vecino_hambre') ?? 0,
          ),
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
    for (final c in [
      _celular,
      _codigo,
      _nombres,
      _apellidos,
      _departamento,
      _provincia,
      _distrito,
    ]) {
      c.dispose();
    }
    _datos?.dispose();
    super.dispose();
  }

  void _ir(int paso) => setState(() => _paso = paso);

  String _telefono() => '+51${_celular.text.replaceAll(RegExp(r'\D'), '')}';

  Future<void> _enviarCodigo() async {
    if (_verificandoTelefono) return;
    if (!_form.currentState!.validate()) return;
    final gateway = context.read<AuthGateway?>();
    final store = context.read<UserProfileStore?>();
    if (gateway == null || store == null) {
      _mostrarErrorTelefono('No se pudo preparar la verificación.');
      return;
    }
    setState(() => _verificandoTelefono = true);
    try {
      final telefono = _telefono();
      final uid = await gateway.ensureSignedIn();
      final existe = await store.phoneExists(telefono);
      final perfilPropio = await store.load(
        uid,
        fallbackName: 'Vecino',
        fallbackBio:
        'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
        fallbackDepartment: '',
        fallbackProvince: '',
        fallbackDistrict: '',
      );
      _perfilExistente = perfilPropio;
      _registroNuevo = !existe && perfilPropio == null;
      await gateway.sendPhoneCode(telefono);
      _telefonoVerificado = telefono;
      if (mounted) _ir(_registroNuevo ? 2 : 3);
    } on AuthFailure catch (error) {
      if (mounted) {
        _mostrarErrorTelefono(switch (error.reason) {
          AuthFailureReason.noConnection =>
          'Sin conexión. Inténtalo nuevamente.',
          AuthFailureReason.tooManyRequests =>
          'Demasiados intentos. Espera unos minutos.',
          AuthFailureReason.anonymousDisabled =>
          'Activa el proveedor Anónimo en Firebase Console: Authentication > Proveedores de acceso.',
          _ => 'No se pudo preparar el código de prueba.',
        });
      }
    } on FirebaseException catch (error) {
      debugPrint(
        'No se pudo consultar el perfil en Firestore '
            '(code=${error.code}): ${error.message}',
      );
      if (mounted) {
        _mostrarErrorTelefono(
          error.code == 'permission-denied'
              ? 'Firebase rechazó el acceso. Publica las reglas de Firestore.'
              : 'No se pudo conectar con Firestore (${error.code}).',
        );
      }
    } catch (error) {
      debugPrint('No se pudo preparar el código de prueba: $error');
      if (mounted) {
        _mostrarErrorTelefono('No se pudo preparar el código de prueba.');
      }
    } finally {
      if (mounted) setState(() => _verificandoTelefono = false);
    }
  }

  Future<void> _verificarTelefono() async {
    if (!_form.currentState!.validate()) return;
    final gateway = context.read<AuthGateway?>();
    final store = context.read<UserProfileStore?>();
    if (gateway == null) {
      _mostrarErrorTelefono('No se pudo verificar el código.');
      return;
    }
    setState(() => _verificandoTelefono = true);
    try {
      await gateway.signInWithPhoneCode(_codigo.text.trim());
      if (!_registroNuevo) {
        UserProfile? profile = _perfilExistente;
        final currentUid = gateway.currentUid;
        if (profile == null && store != null) {
          try {
            profile = await store.loadByPhone(
              _telefonoVerificado,
              fallbackName: 'Vecino',
              fallbackBio:
              'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
              fallbackDepartment: '',
              fallbackProvince: '',
              fallbackDistrict: '',
            );
            if (profile == null && currentUid != null) {
              profile = await store.load(
                currentUid,
                fallbackName: 'Vecino',
                fallbackBio:
                'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
                fallbackDepartment: '',
                fallbackProvince: '',
                fallbackDistrict: '',
              );
            }
          } on FirebaseException catch (error) {
            debugPrint(
              'No se pudo cargar el perfil del UID '
                  '(code=${error.code}): ${error.message}',
            );
            if (mounted) {
              _mostrarErrorTelefono(
                error.code == 'permission-denied'
                    ? 'Firebase rechazó el acceso. Completa tus datos para continuar.'
                    : 'No se pudo recuperar tu perfil. Completa tus datos para continuar.',
              );
            }
          } catch (error) {
            debugPrint('No se pudo cargar el perfil del UID: $error');
            if (mounted) {
              _mostrarErrorTelefono(
                'No se pudo recuperar tu perfil. Completa tus datos para continuar.',
              );
            }
          }
        }
        final loadedProfile = profile;
        if (loadedProfile != null) {
          _perfilExistente = loadedProfile;
          _nombreAutenticado = loadedProfile.name;
          if (_tieneUbicacion(loadedProfile)) {
            await _guardarPerfilLocal(loadedProfile);
            if (mounted) {
              setState(() => _datos = _DatosBarrio(_prefs, loadedProfile));
              widget.onAuthenticated?.call();
            }
            return;
          }
        }
      } else {
        _nombreAutenticado =
        '${_nombres.text.trim()} ${_apellidos.text.trim()}';
      }
      if (mounted) _ir(4);
    } on AuthFailure catch (error) {
      if (mounted) {
        _mostrarErrorTelefono(switch (error.reason) {
          AuthFailureReason.invalidCode => 'El código no es válido.',
          AuthFailureReason.noConnection =>
          'Sin conexión. Inténtalo nuevamente.',
          _ => 'No se pudo verificar el código.',
        });
      }
    } on FirebaseException catch (error) {
      debugPrint(
        'No se pudo verificar el código '
            '(code=${error.code}): ${error.message}',
      );
      if (mounted) {
        _mostrarErrorTelefono(
          error.code == 'permission-denied'
              ? 'Firebase rechazó el acceso. Publica las reglas de Firestore.'
              : 'No se pudo verificar el código (${error.code}).',
        );
      }
    } catch (error) {
      debugPrint('No se pudo verificar el código: $error');
      if (mounted) _mostrarErrorTelefono('No se pudo verificar el código.');
    } finally {
      if (mounted) setState(() => _verificandoTelefono = false);
    }
  }

  void _mostrarErrorTelefono(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _continuarConGoogle() async {
    if (_iniciandoGoogle) return;
    setState(() => _iniciandoGoogle = true);
    try {
      final gateway = context.read<AuthGateway?>();
      final store = context.read<UserProfileStore?>();
      if (gateway == null) {
        throw const AuthFailure(AuthFailureReason.unavailable);
      }
      await gateway.signInWithGoogle();
      final nombre = gateway.currentDisplayName?.trim();
      if (nombre != null && nombre.isNotEmpty) {
        _nombreAutenticado = nombre;
      }
      final uid = gateway.currentUid;
      if (store != null && uid != null) {
        try {
          final existing = await store.load(
            uid,
            fallbackName: _nombreAutenticado,
            fallbackBio:
            'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
            fallbackDepartment: '',
            fallbackProvince: '',
            fallbackDistrict: '',
          );
          if (existing != null) {
            _perfilExistente = existing;
            _nombreAutenticado = existing.name;
            if (_tieneUbicacion(existing)) {
              await _guardarPerfilLocal(existing);
              if (mounted) {
                setState(() => _datos = _DatosBarrio(_prefs, existing));
                widget.onAuthenticated?.call();
              }
              return;
            }
          }
        } catch (error) {
          debugPrint('No se pudo recuperar el perfil de Google: $error');
        }
      }
      if (mounted) _ir(4);
    } on AuthFailure catch (error) {
      if (!mounted) return;
      final mensaje = switch (error.reason) {
        AuthFailureReason.noConnection =>
        'Sin conexión. Conéctate y vuelve a intentarlo.',
        AuthFailureReason.cancelled => 'Inicio de sesión cancelado.',
        AuthFailureReason.invalidCode || AuthFailureReason.tooManyRequests =>
        'No se pudo iniciar sesión con Google. Inténtalo otra vez.',
        AuthFailureReason.anonymousDisabled || AuthFailureReason.unavailable =>
        'No se pudo iniciar sesión con Google. Inténtalo otra vez.',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(mensaje)));
    } finally {
      if (mounted) setState(() => _iniciandoGoogle = false);
    }
  }

  Future<void> _usarUbicacion() async {
    if (_obteniendoUbicacion) return;
    setState(() {
      _obteniendoUbicacion = true;
      _errorUbicacion = null;
      _accionAjustesUbicacion = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const FormatException(
          'Activa la ubicación del dispositivo para continuar.',
        );
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw _LocationLoginException(
          'Necesitamos permiso de ubicación. También puedes completar los campos manualmente.',
          canOpenSettings: permiso == LocationPermission.deniedForever,
        );
      }

      final posicion = await _obtenerPosicion();
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '${posicion.latitude}',
        'lon': '${posicion.longitude}',
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '10',
        'accept-language': 'es',
      });
      final headers = kIsWeb
          ? const <String, String>{}
          : const <String, String>{
        'User-Agent': 'hackaton-hello-world/1.0 (AyniVeci)',
      };
      final respuesta = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (respuesta.statusCode != 200) {
        throw const FormatException(
          'No pudimos consultar la dirección de tu ubicación.',
        );
      }

      final json = jsonDecode(respuesta.body);
      if (json is! Map<String, dynamic> || json['address'] is! Map) {
        throw const FormatException(
          'No encontramos una dirección para tu ubicación.',
        );
      }
      final address = Map<String, dynamic>.from(json['address'] as Map);
      final departamento = _firstAddressValue(address, const [
        'state',
        'region',
        'state_district',
      ]);
      final provincia = _firstAddressValue(address, const [
        'county',
        'province',
        'municipality',
      ]);
      final distrito = _firstAddressValue(address, const [
        'city_district',
        'district',
        'town',
        'city',
        'village',
      ]);
      if (departamento == null || provincia == null || distrito == null) {
        throw const FormatException(
          'La dirección no contiene departamento, provincia y distrito.',
        );
      }

      final departamentoCatalogo = _encontrar(peruLocations.keys, departamento);
      final provinciaCatalogo = departamentoCatalogo == null
          ? null
          : _encontrar(peruLocations[departamentoCatalogo]!.keys, provincia);
      final distritoCatalogo =
      departamentoCatalogo == null || provinciaCatalogo == null
          ? null
          : _encontrar(
        peruLocations[departamentoCatalogo]![provinciaCatalogo]!,
        distrito,
      );
      if (departamentoCatalogo == null ||
          provinciaCatalogo == null ||
          distritoCatalogo == null) {
        throw const FormatException(
          'No encontramos esa ubicación en el catálogo de Perú. Selecciónala manualmente.',
        );
      }
      _seleccionarDepartamento(departamentoCatalogo);
      _seleccionarProvincia(provinciaCatalogo);
      _seleccionarDistrito(distritoCatalogo);
      if (mounted) {
        setState(() {
          _obteniendoUbicacion = false;
          _errorUbicacion = null;
        });
      }
    } on _LocationLoginException catch (error) {
      _mostrarErrorUbicacion(
        error.message,
        canOpenSettings: error.canOpenSettings,
        accionAjustes: error.canOpenSettings
            ? () {
          Geolocator.openAppSettings();
        }
            : null,
      );
    } on FormatException catch (error) {
      _mostrarErrorUbicacion(error.message);
    } on LocationServiceDisabledException {
      _mostrarErrorUbicacion(
        'Activa la ubicación del dispositivo para continuar.',
        accionAjustes: () {
          Geolocator.openLocationSettings();
        },
      );
    } on PermissionDeniedException {
      _mostrarErrorUbicacion(
        'Necesitamos permiso de ubicación. También puedes completar los campos manualmente.',
        accionAjustes: () {
          Geolocator.openAppSettings();
        },
      );
    } on TimeoutException {
      _mostrarErrorUbicacion(
        'La ubicación tardó demasiado. Inténtalo otra vez o completa los campos manualmente.',
      );
    } catch (error) {
      _mostrarErrorUbicacion(
        'No pudimos obtener tu ubicación. Puedes completar los campos manualmente.',
      );
      debugPrint('No se pudo obtener la ubicación del login: $error');
    }
  }

  Future<Position> _obtenerPosicion() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      final ultima = await Geolocator.getLastKnownPosition();
      if (ultima != null) return ultima;
      rethrow;
    }
  }

  void _mostrarErrorUbicacion(
      String mensaje, {
        bool canOpenSettings = false,
        VoidCallback? accionAjustes,
      }) {
    if (!mounted) return;
    setState(() {
      _obteniendoUbicacion = false;
      _errorUbicacion = canOpenSettings
          ? '$mensaje Pulsa "Abrir ajustes" para habilitarlo.'
          : mensaje;
      _accionAjustesUbicacion = accionAjustes;
    });
  }

  String? _firstAddressValue(Map<String, dynamic> address, List<String> keys) {
    for (final key in keys) {
      final value = address[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  void _seleccionarDepartamento(String? valor) {
    _departamentoSeleccionado = valor;
    _departamento.text = valor ?? '';
    _provinciaSeleccionada = null;
    _distritoSeleccionado = null;
    _provincia.clear();
    _distrito.clear();
    if (mounted) setState(() {});
  }

  void _seleccionarProvincia(String? valor) {
    _provinciaSeleccionada = valor;
    _provincia.text = valor ?? '';
    _distritoSeleccionado = null;
    _distrito.clear();
    if (mounted) setState(() {});
  }

  void _seleccionarDistrito(String? valor) {
    _distritoSeleccionado = valor;
    _distrito.text = valor ?? '';
    if (mounted) setState(() {});
  }

  String? _encontrar(Iterable<String> opciones, String valor) {
    final buscado = _normalizar(valor);
    for (final opcion in opciones) {
      if (_normalizar(opcion) == buscado) return opcion;
    }
    return null;
  }

  Future<void> _confirmar() async {
    final dep = _departamento.text.trim();
    final prov = _provincia.text.trim();
    final dist = _distrito.text.trim();
    final auth = context.read<AuthGateway?>();
    final store = context.read<UserProfileStore?>();
    final uid = auth?.currentUid;
    setState(
          () => _datos = _DatosBarrio(
        _prefs,
        UserProfile(
          department: dep,
          province: prov,
          district: dist,
          name: _nombreAutenticado,
          phoneNumber: _telefonoVerificado,
          bio:
          _perfilExistente?.bio ??
              'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
          xp: _perfilExistente?.xp ?? 0,
          fichas: _perfilExistente?.fichas ?? 0,
          stars: _perfilExistente?.stars ?? 0,
          favors: _perfilExistente?.favors ?? 0,
          tools: _perfilExistente?.tools ?? 0,
          petHunger: _perfilExistente?.petHunger ?? 0,
        ),
      ),
    );
    try {
      await _prefs.setString('vecino_departamento', dep);
      await _prefs.setString('vecino_provincia', prov);
      await _prefs.setString('vecino_distrito', dist);
      await _prefs.setString('vecino_nombre', _nombreAutenticado);
      await _prefs.setString('vecino_telefono', _telefonoVerificado);
      if (uid != null) await _prefs.setString('vecino_profile_uid', uid);
      if (store != null && uid != null) {
        if (mounted) {
          unawaited(
            _saveRegistrationProfile(
              store,
              uid,
              _datos!.toProfile(),
              ScaffoldMessenger.of(context),
            ),
          );
        }
      }
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
      'Crea tu perfil',
      'Revisa tus mensajes',
      '¿Dónde está tu barrio?',
      'Confirma tu barrio',
    ];
    final contenido = switch (_paso) {
      0 => <Widget>[_bienvenidaLogin()],
      1 => <Widget>[
        label(
          'Usa el código de verificación de prueba: 123456.',
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
        _accion(
          _verificandoTelefono ? 'Preparando código...' : 'Continuar',
          _enviarCodigo,
        ),
      ],
      2 => <Widget>[
        label('Crea tu perfil con tu nombre y apellido.', 16, color: muted),
        _campo(_nombres, 'Nombres', minimo: 2),
        _campo(_apellidos, 'Apellidos', minimo: 2),
        _accion('Continuar a verificación', () {
          if (_form.currentState!.validate()) _ir(3);
        }),
      ],
      3 => <Widget>[
        label(
          'Escribe el código de prueba para $_telefonoVerificado.',
          16,
          color: muted,
        ),
        _campo(
          _codigo,
          'Código de 6 dígitos',
          tipo: TextInputType.number,
          minimo: 6,
          soloDigitos: true,
          esperado: phoneTestCode,
        ),
        _accion(
          _verificandoTelefono ? 'Verificando...' : 'Verificar y continuar',
          _verificarTelefono,
        ),
      ],
      4 => <Widget>[
        label(
          'Usa tu ubicación para completar la zona automáticamente o ingresa los datos manualmente.',
          16,
          color: muted,
        ),
        OutlinedButton.icon(
          onPressed: _obteniendoUbicacion ? null : _usarUbicacion,
          icon: _obteniendoUbicacion
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.my_location),
          label: Text(
            _obteniendoUbicacion
                ? 'Obteniendo ubicación...'
                : 'Usar mi ubicación',
          ),
        ),
        if (_errorUbicacion != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _errorUbicacion!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              if (_accionAjustesUbicacion != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _accionAjustesUbicacion,
                    icon: const Icon(Icons.settings),
                    label: const Text('Abrir ajustes'),
                  ),
                ),
            ],
          ),
        _selectorUbicacion(
          context,
          'Departamento',
          _departamentoSeleccionado,
          peruLocations.keys,
          _seleccionarDepartamento,
        ),
        _selectorUbicacion(
          context,
          'Provincia',
          _provinciaSeleccionada,
          _departamentoSeleccionado == null
              ? const <String>[]
              : peruLocations[_departamentoSeleccionado]!.keys,
          _seleccionarProvincia,
        ),
        _selectorUbicacion(
          context,
          'Distrito',
          _distritoSeleccionado,
          _departamentoSeleccionado == null || _provinciaSeleccionada == null
              ? const <String>[]
              : peruLocations[_departamentoSeleccionado]![_provinciaSeleccionada]!,
          _seleccionarDistrito,
        ),
        _accion('Revisar distrito', () {
          if (_form.currentState!.validate()) _ir(5);
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
        title: const Text('AyniVeci'),
        leading: _paso == 0
            ? null
            : BackButton(onPressed: () => _ir(_paso - 1)),
      ),
      body: _contenido(
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_paso != 0) label(titulos[_paso], 29, bold: true),
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

  Widget _bienvenidaLogin() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 20),
      Center(child: icono('Firulais', 116)),
      const SizedBox(height: 12),
      Center(child: label('AYNI VECI', 15, bold: true, color: orange)),
      const SizedBox(height: 8),
      Center(child: label('Hola, vecino', 28, bold: true)),
      const SizedBox(height: 6),
      Center(
        child: label('Entra para conectar con tu comunidad.', 15, color: muted),
      ),
      const SizedBox(height: 30),
      SizedBox(
        width: double.infinity,
        child: _accion('Continuar con celular', () => _ir(1)),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: _iniciandoGoogle ? null : _continuarConGoogle,
          icon: _iniciandoGoogle
              ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.account_circle_outlined),
          label: Text(
            _iniciandoGoogle
                ? 'Conectando con Google...'
                : 'Continuar con Google',
          ),
        ),
      ),
    ],
  );
}

Future<void> _saveRegistrationProfile(
    UserProfileStore store,
    String uid,
    UserProfile profile,
    ScaffoldMessengerState messenger,
    ) async {
  try {
    await store.save(uid, profile).timeout(const Duration(seconds: 12));
  } catch (_) {
    if (!messenger.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Tu perfil se guardó en este dispositivo. Falta sincronizarlo.',
        ),
        action: SnackBarAction(
          label: 'Reintentar',
          onPressed: () => unawaited(
            _saveRegistrationProfile(store, uid, profile, messenger),
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
    }) => TextFormField(
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
    if (soloDigitos && s.length != minimo) return 'Escribe $minimo dígitos.';
    if (s.length < minimo) return 'Completa este campo.';
    if (esperado != null && s != esperado) return 'Revisa el código de prueba.';
    return null;
  },
);

String _normalizar(String texto) {
  const equivalencias = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var resultado = texto.trim().toLowerCase();
  equivalencias.forEach((origen, destino) {
    resultado = resultado.replaceAll(origen, destino);
  });
  return resultado;
}

Widget _selectorUbicacion(
    BuildContext context,
    String titulo,
    String? valor,
    Iterable<String> opciones,
    ValueChanged<String> onSelected,
    ) {
  final disponibles = opciones.toList(growable: false);
  return FormField<String>(
    key: ValueKey('$titulo:$valor'),
    initialValue: valor,
    validator: (seleccion) => seleccion == null || seleccion.isEmpty
        ? 'Selecciona este campo.'
        : null,
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: disponibles.isEmpty
              ? null
              : () async {
            final seleccion = await showDialog<String>(
              context: context,
              builder: (_) => _BusquedaUbicacion(
                titulo: titulo,
                opciones: disponibles,
              ),
            );
            if (seleccion != null) {
              onSelected(seleccion);
              field.didChange(seleccion);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: titulo,
              filled: true,
              fillColor: paper,
              border: const OutlineInputBorder(),
              enabled: disponibles.isNotEmpty,
              errorText: field.errorText,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valor ??
                        (disponibles.isEmpty
                            ? 'Selecciona el nivel anterior'
                            : 'Seleccionar'),
                    style: TextStyle(color: valor == null ? muted : ink),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _BusquedaUbicacion extends StatefulWidget {
  const _BusquedaUbicacion({required this.titulo, required this.opciones});

  final String titulo;
  final List<String> opciones;

  @override
  State<_BusquedaUbicacion> createState() => _BusquedaUbicacionState();
}

class _BusquedaUbicacionState extends State<_BusquedaUbicacion> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final opciones = widget.opciones
        .where((opcion) => _normalizar(opcion).contains(_normalizar(_filtro)))
        .toList(growable: false);
    return AlertDialog(
      title: Text('Buscar ${widget.titulo.toLowerCase()}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Escribe para buscar',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (valor) => setState(() => _filtro = valor),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: opciones.length,
                itemBuilder: (_, indice) => ListTile(
                  title: Text(opciones[indice]),
                  onTap: () => Navigator.pop(context, opciones[indice]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    child: ListView(padding: const EdgeInsets.all(16), children: [child]),
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