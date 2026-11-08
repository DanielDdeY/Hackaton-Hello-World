part of 'home.dart';

class _MiPerfilPage extends StatefulWidget {
  const _MiPerfilPage({required this.datos});

  final _DatosBarrio datos;

  @override
  State<_MiPerfilPage> createState() => _MiPerfilPageState();
}

class _MiPerfilPageState extends State<_MiPerfilPage> {
  int _itemsMochilaListos = 0;
  bool _bonoMochilaReclamado = false;

  @override
  void initState() {
    super.initState();
    _cargarMochila();
  }

  Future<void> _cargarMochila() async {
    final items = await BackpackChecklistStore.load();
    final reclamado = await MochilaVerificacion.isBonoReclamado();
    if (mounted) {
      setState(() {
        _itemsMochilaListos = items.values.where((v) => v).length;
        _bonoMochilaReclamado = reclamado;
      });
    }
  }

  Future<void> _abrirMascota() async {
    final uid = context.read<AuthGateway?>()?.currentUid ?? 'usr_local';
    final repo = LocalMascotaRepository(preferences: widget.datos.preferencias);

    await Navigator.of(context).push(
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

  Future<void> _abrirMochila() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Ayuda y Prevención')),
          body: const AyudaPrevencionPage(),
        ),
      ),
    );
    if (mounted) {
      await _cargarMochila();
    }
  }

  Future<void> _abrirContactosSos() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SosSmsContactsPage()),
    );
  }

  Future<void> _abrirEditar() async {
    final actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _EditarInformacionPage(datos: widget.datos),
      ),
    );
    if (actualizado == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthGateway?>();
    final users = context.read<UserRepository?>();
    final uid = auth?.currentUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        elevation: 0,
      ),
      body: StreamBuilder<AppUser>(
        stream: users != null && uid != null && uid.isNotEmpty
            ? users.watchUserStats(uid)
            : null,
        builder: (context, snapshot) {
          final stats = snapshot.data;
          if (stats != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.datos.syncEconomy(stats);
            });
          }
          return ListenableBuilder(
            listenable: widget.datos,
            builder: (context, _) {
              final xp = stats?.xpTotal ?? widget.datos.xp;
              final monedas = stats?.availableCoins ?? widget.datos.fichas;
              final xpMes = stats?.effectiveMonthlyXp ?? widget.datos.weeklyXp;
              final estrellas = stats != null && stats.reviewCount > 0
                  ? stats.averageStars
                  : widget.datos.stars.toDouble();
              final totalResenas = stats?.reviewCount ?? 0;

              final listaInsignias = [
                if (_bonoMochilaReclamado) 'vecino-preparado',
                ...widget.datos.insignias,
              ];

              return RefreshIndicator(
                onRefresh: () async {
                  await _cargarMochila();
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    PerfilCabecera(
                      nombre: widget.datos.nombre,
                      iniciales: widget.datos.iniciales,
                      distrito: widget.datos.distrito,
                      provincia: widget.datos.provincia,
                      xp: xp,
                      foto: widget.datos.foto,
                    ),
                    const SizedBox(height: 16),
                    PerfilResumen(
                      xpMes: xpMes,
                      fichas: monedas,
                      estrellas: estrellas,
                      totalResenas: totalResenas,
                    ),
                    const SizedBox(height: 16),
                    PerfilTarjetasDestacadas(
                      xp: xp,
                      bonoMochilaReclamado: _bonoMochilaReclamado,
                      itemsMochilaListos: _itemsMochilaListos,
                      onAbrirMascota: _abrirMascota,
                      onAbrirMochila: _abrirMochila,
                    ),
                    const SizedBox(height: 16),
                    PerfilInsignias(insignias: listaInsignias),
                    const SizedBox(height: 16),
                    PerfilActividad(
                      favoresCompletados: widget.datos.favoresCompletados,
                      eventosAsistidos: widget.datos.eventosAsistidos,
                      reconocimientos: widget.datos.reconocimientos,
                      rachaSemanal: widget.datos.rachaSemanal,
                    ),
                    const SizedBox(height: 16),
                    PerfilDatosPersonales(
                      zona: widget.datos.zona,
                      telefono: widget.datos.phoneNumber,
                      bio: widget.datos.bio,
                      onEditar: _abrirEditar,
                      onContactosSos: _abrirContactosSos,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
