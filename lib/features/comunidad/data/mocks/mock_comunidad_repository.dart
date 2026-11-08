import '../../domain/entities/evento_comunitario.dart';
import '../../domain/entities/favor.dart';
import '../../domain/entities/vecino_ranking.dart';
import '../../domain/repositories/comunidad_repository.dart';

class MockComunidadRepository implements ComunidadRepository {
  MockComunidadRepository({
    this.usuarioActualId = 'usr_actual',
    this.usuarioActualNombre = 'Tú (Vecino Activo)',
  }) {
    _inicializarDatos();
  }

  @override
  final String usuarioActualId;
  final String usuarioActualNombre;

  late List<Favor> _favores;
  late List<EventoComunitario> _eventos;
  late List<VecinoRanking> _rankingAte;
  late BuenVecinoSemana _buenVecino;

  void _inicializarDatos() {
    _favores = [
      Favor(
        id: 'fav_01',
        titulo: 'Prestar escalera tijera de 2 metros',
        descripcion: 'Necesito pintar el alero de la fachada. La devolveré limpia y el mismo día por la tarde.',
        categoria: CategoriaFavor.herramientas,
        tamano: TamanoFavor.mini,
        estado: EstadoFavor.abierto,
        cuposTotales: 1,
        cuposTomados: 0,
        solicitanteId: 'usr_carmen',
        solicitanteNombre: 'Doña Carmen Rosa',
        solicitanteTelefono: '987654321',
        cuadraNombre: 'Calle Los Pinos Cdra. 3',
        ubicacionAproximada: 'A 80 metros de tu casa',
        ubicacionExacta: 'Calle Los Pinos 342, Dpto 201',
        creadoEn: DateTime.now().subtract(const Duration(minutes: 45)),
        venceEn: DateTime.now().add(const Duration(hours: 6)),
        monedasRecompensa: TamanoFavor.mini.monedasBase,
        xpRecompensa: TamanoFavor.mini.xpBase,
      ),
      Favor(
        id: 'fav_02',
        titulo: 'Apoyo con compras pesadas en el mercado',
        descripcion: 'Tengo dificultad para cargar bolsas pesadas de verduras y abarrotes. Sería acompañarme unas 3 cuadras.',
        categoria: CategoriaFavor.compras,
        tamano: TamanoFavor.medio,
        estado: EstadoFavor.abierto,
        cuposTotales: 1,
        cuposTomados: 0,
        solicitanteId: 'usr_don_luis',
        solicitanteNombre: 'Don Luis Morales (78 años)',
        solicitanteTelefono: '912345678',
        cuadraNombre: 'Jr. Las Palmeras Cdra. 1',
        ubicacionAproximada: 'A 150 metros (frente al parque)',
        ubicacionExacta: 'Jr. Las Palmeras 115',
        creadoEn: DateTime.now().subtract(const Duration(hours: 1)),
        venceEn: DateTime.now().add(const Duration(hours: 4)),
        monedasRecompensa: TamanoFavor.medio.monedasBase,
        xpRecompensa: TamanoFavor.medio.xpBase,
      ),
      Favor(
        id: 'fav_03',
        titulo: 'Jornada de pintado de mural vecinal',
        descripcion: 'Vamos a recuperar la pared exterior del parque central. Se requiere apoyo con rodillos y brochas.',
        categoria: CategoriaFavor.limpieza,
        tamano: TamanoFavor.comunitario,
        estado: EstadoFavor.abierto,
        cuposTotales: 5,
        cuposTomados: 3,
        solicitanteId: 'usr_coordinador',
        solicitanteNombre: 'Junta de Jóvenes Unidos',
        solicitanteTelefono: '998877665',
        cuadraNombre: 'Parque Central Sector 2',
        ubicacionAproximada: 'Parque de la Amistad',
        ubicacionExacta: 'Av. Principal s/n esq. Los Álamos',
        creadoEn: DateTime.now().subtract(const Duration(hours: 3)),
        venceEn: DateTime.now().add(const Duration(days: 1)),
        monedasRecompensa: TamanoFavor.comunitario.monedasBase,
        xpRecompensa: TamanoFavor.comunitario.xpBase,
        participantes: [
          ParticipanteFavor(
            uid: 'usr_ana',
            nombre: 'Ana Belén',
            estado: 'aceptado',
            aceptadoEn: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          ParticipanteFavor(
            uid: 'usr_marcos',
            nombre: 'Marcos R.',
            estado: 'aceptado',
            aceptadoEn: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          ParticipanteFavor(
            uid: 'usr_pedro',
            nombre: 'Pedro G.',
            estado: 'aceptado',
            aceptadoEn: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
      ),
      Favor(
        id: 'fav_04',
        titulo: 'Revisión y cambio de empaque de caño que gotea',
        descripcion: 'El lavadero de la cocina tiene una fuga leve. Si algún vecino tiene llave inglesa y me da una mano.',
        categoria: CategoriaFavor.reparacion,
        tamano: TamanoFavor.medio,
        estado: EstadoFavor.enCurso,
        cuposTotales: 1,
        cuposTomados: 1,
        solicitanteId: 'usr_mariela',
        solicitanteNombre: 'Mariela Paredes',
        solicitanteTelefono: '955443322',
        cuadraNombre: 'Calle Los Pinos Cdra. 4',
        ubicacionAproximada: 'A la vuelta de tu cuadra',
        ubicacionExacta: 'Calle Los Pinos 420 int. 3',
        creadoEn: DateTime.now().subtract(const Duration(hours: 5)),
        venceEn: DateTime.now().add(const Duration(hours: 2)),
        monedasRecompensa: TamanoFavor.medio.monedasBase,
        xpRecompensa: TamanoFavor.medio.xpBase,
        participantes: [
          ParticipanteFavor(
            uid: usuarioActualId,
            nombre: usuarioActualNombre,
            estado: 'enCurso',
            aceptadoEn: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    ];

    _eventos = [
      EventoComunitario(
        id: 'evt_01',
        titulo: 'Reunión Ordinaria de Junta Vecinal de Cuadra',
        descripcion: 'Trataremos sobre las nuevas cámaras de seguridad de la esquina y la coordinación del simulacro.',
        tipo: TipoEvento.reunion,
        fecha: DateTime.now().add(const Duration(days: 1, hours: 4)),
        lugar: 'Local Comunal (Jr. Las Palmeras 230)',
        cuadraNombre: 'Sector 2',
        organizadorNombre: 'Sr. Humberto (Delegado)',
        requiereAsistencia: true,
        asistenciasVoy: 14,
        asistenciasInteresa: 6,
        miRespuesta: RespuestaEvento.voy,
      ),
      EventoComunitario(
        id: 'evt_02',
        titulo: 'Faena de arborización y limpieza en el pasaje',
        descripcion: 'Colocaremos plantones y tierra de chacra en las jardineras comunitarias. Traer guantes y bolsas.',
        tipo: TipoEvento.faena,
        fecha: DateTime.now().add(const Duration(days: 3, hours: 2)),
        lugar: 'Pasaje San Martín con Los Pinos',
        cuadraNombre: 'Cdra. 3 Los Pinos',
        organizadorNombre: 'Comisión de Medio Ambiente',
        requiereAsistencia: false,
        asistenciasVoy: 8,
        asistenciasInteresa: 12,
        miRespuesta: RespuestaEvento.meInteresa,
      ),
      EventoComunitario(
        id: 'evt_03',
        titulo: 'Taller de Primeros Auxilios y Mochila de Emergencia',
        descripcion: 'Capacitación dictada por brigadistas voluntarios de INDECI. Aprenderemos técnicas de vendaje y RCP básico.',
        tipo: TipoEvento.seguridad,
        fecha: DateTime.now().add(const Duration(days: 5)),
        lugar: 'Cancha deportiva Los Sauces',
        cuadraNombre: 'Manzana C',
        organizadorNombre: 'Brigada Vecinal de Defensa Civil',
        requiereAsistencia: true,
        asistenciasVoy: 22,
        asistenciasInteresa: 19,
        miRespuesta: RespuestaEvento.ninguna,
      ),
    ];

    _rankingAte = [
      const VecinoRanking(
        uid: 'usr_roberto',
        nombre: 'Roberto Huamán',
        iniciales: 'RH',
        distrito: 'Ate',
        xpPeriodo: 380,
        posicion: 1,
        nivel: 12,
        bio: 'Coordino la brigada de defensa civil y apoyo en simulacros del barrio.',
        insignias: ['Guardián del barrio', 'Líder comunitario'],
        favoresCompletados: 34,
        estrellas: 48,
        eventosAsistidos: 21,
        reconocimientos: 26,
        rachaSemanal: 8,
        tendencia: TendenciaRanking.sube,
        xpTotal: 1280,
      ),
      const VecinoRanking(
        uid: 'usr_hilda',
        nombre: 'Hilda Quispe',
        iniciales: 'HQ',
        distrito: 'Ate',
        xpPeriodo: 300,
        posicion: 2,
        nivel: 10,
        bio: 'Organizo la olla común y la campaña de reciclaje de la zona.',
        insignias: ['Corazón de barrio', 'Manos amigas'],
        favoresCompletados: 28,
        estrellas: 39,
        eventosAsistidos: 17,
        reconocimientos: 22,
        rachaSemanal: 7,
        tendencia: TendenciaRanking.igual,
        xpTotal: 1040,
      ),
      const VecinoRanking(
        uid: 'usr_carmen',
        nombre: 'Carmen Rosa Díaz',
        iniciales: 'CR',
        distrito: 'Ate',
        xpPeriodo: 240,
        posicion: 3,
        nivel: 8,
        bio: 'Me gusta cuidar a las mascotas del barrio y apoyar a los vecinos nuevos.',
        insignias: ['Buen vecino', 'Corazón de barrio'],
        favoresCompletados: 19,
        estrellas: 31,
        eventosAsistidos: 12,
        reconocimientos: 18,
        rachaSemanal: 6,
        tendencia: TendenciaRanking.sube,
        xpTotal: 820,
      ),
      const VecinoRanking(
        uid: 'usr_ana',
        nombre: 'Ana Belén',
        iniciales: 'AB',
        distrito: 'Ate',
        xpPeriodo: 210,
        posicion: 4,
        nivel: 7,
        bio: 'Voluntaria en las faenas de limpieza y talleres de primeros auxilios.',
        insignias: ['Manos amigas'],
        favoresCompletados: 16,
        estrellas: 27,
        eventosAsistidos: 14,
        reconocimientos: 11,
        rachaSemanal: 5,
        tendencia: TendenciaRanking.sube,
        xpTotal: 760,
      ),
      const VecinoRanking(
        uid: 'usr_sofia',
        nombre: 'Sofía Torres',
        iniciales: 'ST',
        distrito: 'Ate',
        xpPeriodo: 200,
        posicion: 5,
        nivel: 7,
        bio: 'Profesora y coordinadora del grupo de jóvenes del distrito.',
        insignias: ['Guía juvenil'],
        favoresCompletados: 15,
        estrellas: 24,
        eventosAsistidos: 13,
        reconocimientos: 9,
        rachaSemanal: 4,
        tendencia: TendenciaRanking.igual,
        xpTotal: 710,
      ),
      VecinoRanking(
        uid: usuarioActualId,
        nombre: usuarioActualNombre,
        iniciales: 'TÚ',
        distrito: 'Ate',
        xpPeriodo: 180,
        posicion: 6,
        nivel: 6,
        esUsuarioActual: true,
        bio: 'Me gusta ayudar con reparaciones y prestar herramientas a mis vecinos.',
        insignias: ['Vecino activo'],
        favoresCompletados: 12,
        estrellas: 21,
        eventosAsistidos: 9,
        reconocimientos: 7,
        rachaSemanal: 4,
        tendencia: TendenciaRanking.sube,
        xpTotal: 640,
      ),
      const VecinoRanking(
        uid: 'usr_mariela',
        nombre: 'Mariela Paredes',
        iniciales: 'MP',
        distrito: 'Ate',
        xpPeriodo: 170,
        posicion: 7,
        nivel: 6,
        bio: 'Apoyo en la biblioteca comunal y en la colecta de útiles escolares.',
        insignias: ['Manos amigas'],
        favoresCompletados: 11,
        estrellas: 18,
        eventosAsistidos: 8,
        reconocimientos: 6,
        rachaSemanal: 3,
        tendencia: TendenciaRanking.baja,
        xpTotal: 590,
      ),
      const VecinoRanking(
        uid: 'usr_jorge',
        nombre: 'Jorge Mendoza',
        iniciales: 'JM',
        distrito: 'Ate',
        xpPeriodo: 150,
        posicion: 8,
        nivel: 5,
        bio: 'Electricista del barrio. Siempre disponible para una revisión rápida.',
        insignias: ['Oficio solidario'],
        favoresCompletados: 10,
        estrellas: 16,
        eventosAsistidos: 6,
        reconocimientos: 5,
        rachaSemanal: 3,
        tendencia: TendenciaRanking.igual,
        xpTotal: 540,
      ),
      const VecinoRanking(
        uid: 'usr_marcos',
        nombre: 'Marcos Ríos',
        iniciales: 'MR',
        distrito: 'Ate',
        xpPeriodo: 130,
        posicion: 9,
        nivel: 5,
        bio: 'Participa en las faenas y apoya con el traslado de materiales.',
        insignias: ['Faena frecuente'],
        favoresCompletados: 8,
        estrellas: 13,
        eventosAsistidos: 5,
        reconocimientos: 4,
        rachaSemanal: 2,
        tendencia: TendenciaRanking.sube,
        xpTotal: 470,
      ),
      const VecinoRanking(
        uid: 'usr_pedro',
        nombre: 'Pedro Gómez',
        iniciales: 'PG',
        distrito: 'Ate',
        xpPeriodo: 110,
        posicion: 10,
        nivel: 4,
        bio: 'Vecino nuevo. Le gusta aprender y sumarse a las actividades del barrio.',
        insignias: ['Recién llegado'],
        favoresCompletados: 6,
        estrellas: 10,
        eventosAsistidos: 4,
        reconocimientos: 3,
        rachaSemanal: 2,
        tendencia: TendenciaRanking.sube,
        xpTotal: 390,
      ),
      const VecinoRanking(
        uid: 'usr_lucia',
        nombre: 'Lucía Fernández',
        iniciales: 'LF',
        distrito: 'Ate',
        xpPeriodo: 90,
        posicion: 11,
        nivel: 4,
        bio: 'Ayuda en la difusión de eventos y en el cuidado de las áreas verdes.',
        insignias: ['Vecino activo'],
        favoresCompletados: 5,
        estrellas: 8,
        eventosAsistidos: 3,
        reconocimientos: 2,
        rachaSemanal: 1,
        tendencia: TendenciaRanking.igual,
        xpTotal: 330,
      ),
      const VecinoRanking(
        uid: 'usr_don_luis',
        nombre: 'Don Luis Morales',
        iniciales: 'LM',
        distrito: 'Ate',
        xpPeriodo: 60,
        posicion: 12,
        nivel: 3,
        bio: 'Vecino jubilado. Comparte historias del barrio y consejos de jardinería.',
        insignias: ['Memoria del barrio'],
        favoresCompletados: 3,
        estrellas: 6,
        eventosAsistidos: 2,
        reconocimientos: 4,
        rachaSemanal: 1,
        tendencia: TendenciaRanking.baja,
        xpTotal: 240,
      ),
      const VecinoRanking(
        uid: 'usr_raul',
        nombre: 'Raúl Castillo',
        iniciales: 'RC',
        distrito: 'Ate',
        xpPeriodo: 40,
        posicion: 13,
        nivel: 2,
        bio: 'Estudiante. Colabora con la limpieza del parque los fines de semana.',
        insignias: ['Recién llegado'],
        favoresCompletados: 2,
        estrellas: 4,
        eventosAsistidos: 1,
        reconocimientos: 1,
        rachaSemanal: 1,
        tendencia: TendenciaRanking.igual,
        xpTotal: 160,
      ),
    ];

    _buenVecino = const BuenVecinoSemana(
      uid: 'usr_carmen',
      nombre: 'Doña Carmen Rosa',
      iniciales: 'CR',
      distrito: 'Ate',
      motivo:
          'Por coordinar la olla común de emergencia y cuidar a las mascotas de los vecinos durante el corte de luz.',
      votosReconocimiento: 18,
    );
  }

  @override
  Future<List<Favor>> obtenerFavores({
    CategoriaFavor? categoria,
    TamanoFavor? tamano,
    bool soloConCupo = false,
  }) async {
    return _favores.where((f) {
      if (categoria != null && f.categoria != categoria) return false;
      if (tamano != null && f.tamano != tamano) return false;
      if (soloConCupo && !f.tieneCupo) return false;
      return true;
    }).toList();
  }

  @override
  Future<Favor> agregarFavor(Favor favor) async {
    // Inserta al inicio para que aparezca primero en el feed
    _favores.insert(0, favor);
    return favor;
  }

  @override
  Future<Favor> obtenerFavorPorId(String id) async {
    return _favores.firstWhere((f) => f.id == id);
  }

  @override
  Future<void> aceptarFavor(String favorId) async {
    final idx = _favores.indexWhere((f) => f.id == favorId);
    if (idx == -1) return;
    final f = _favores[idx];
    if (f.cuposTomados >= f.cuposTotales) {
      throw Exception('Cupos agotados para este favor.');
    }
    if (f.solicitanteId == usuarioActualId) {
      throw Exception('No puedes aceptar tu propio favor.');
    }

    final nuevosTomados = f.cuposTomados + 1;
    final nuevoEstado = nuevosTomados >= f.cuposTotales
        ? EstadoFavor.cuposLlenos
        : EstadoFavor.enCurso;

    final nuevosParticipantes = [
      ...f.participantes,
      ParticipanteFavor(
        uid: usuarioActualId,
        nombre: usuarioActualNombre,
        estado: 'enCurso',
        aceptadoEn: DateTime.now(),
      ),
    ];

    _favores[idx] = f.copyWith(
      cuposTomados: nuevosTomados,
      estado: nuevoEstado,
      participantes: nuevosParticipantes,
    );
  }

  @override
  Future<void> marcarTerminado(String favorId) async {
    final idx = _favores.indexWhere((f) => f.id == favorId);
    if (idx == -1) return;
    final f = _favores[idx];

    final actualizados = f.participantes.map((p) {
      if (p.uid == usuarioActualId) {
        return ParticipanteFavor(
          uid: p.uid,
          nombre: p.nombre,
          estado: 'terminado',
          aceptadoEn: p.aceptadoEn,
          terminadoEn: DateTime.now(),
        );
      }
      return p;
    }).toList();

    _favores[idx] = f.copyWith(
      estado: EstadoFavor.esperandoConfirmacion,
      participantes: actualizados,
    );
  }

  @override
  Future<void> confirmarYCalificar(String favorId, double calificacion) async {
    final idx = _favores.indexWhere((f) => f.id == favorId);
    if (idx == -1) return;
    final f = _favores[idx];

    final actualizados = f.participantes.map((p) {
      return ParticipanteFavor(
        uid: p.uid,
        nombre: p.nombre,
        estado: 'confirmado',
        aceptadoEn: p.aceptadoEn,
        terminadoEn: p.terminadoEn ?? DateTime.now(),
        calificacion: calificacion,
      );
    }).toList();

    _favores[idx] = f.copyWith(
      estado: EstadoFavor.completado,
      participantes: actualizados,
    );
  }

  @override
  Future<List<EventoComunitario>> obtenerEventos() async {
    return List.unmodifiable(_eventos);
  }

  @override
  Future<void> responderEvento(
    String eventoId,
    RespuestaEvento respuesta,
  ) async {
    final idx = _eventos.indexWhere((e) => e.id == eventoId);
    if (idx == -1) return;
    final e = _eventos[idx];

    int voy = e.asistenciasVoy;
    int interesa = e.asistenciasInteresa;

    if (e.miRespuesta == RespuestaEvento.voy) voy--;
    if (e.miRespuesta == RespuestaEvento.meInteresa) interesa--;

    if (respuesta == RespuestaEvento.voy) voy++;
    if (respuesta == RespuestaEvento.meInteresa) interesa++;

    _eventos[idx] = e.copyWith(
      miRespuesta: respuesta,
      asistenciasVoy: voy < 0 ? 0 : voy,
      asistenciasInteresa: interesa < 0 ? 0 : interesa,
    );
  }

  @override
  Future<void> verificarAsistencia(String eventoId, String codigo) async {
    final idx = _eventos.indexWhere((e) => e.id == eventoId);
    if (idx == -1) return;
    final e = _eventos[idx];

    // Simula validación de código de delegado vecinal
    if (codigo.trim().isEmpty) {
      throw Exception('El código no puede estar vacío.');
    }

    _eventos[idx] = e.copyWith(
      asistenciaVerificada: true,
      miRespuesta: RespuestaEvento.voy,
    );
  }

  @override
  Future<String> obtenerDistritoActual() async => 'Ate';

  @override
  Future<List<VecinoRanking>> obtenerRanking({
    String ambito = 'distrito',
  }) async {
    return List.unmodifiable(_rankingAte);
  }

  @override
  Future<VecinoPerfil?> obtenerVecino(String uid) async {
    final index = _rankingAte.indexWhere((item) => item.uid == uid);
    if (index == -1) return null;
    return VecinoPerfil.desdeRanking(_rankingAte[index]);
  }

  @override
  Future<BuenVecinoSemana?> obtenerBuenVecinoSemana() async {
    return _buenVecino;
  }

  @override
  Future<void> nominarBuenVecino(String destinoUid, String motivo) async {
    final index = _rankingAte.indexWhere((item) => item.uid == destinoUid);
    if (index != -1) {
      final actual = _rankingAte[index];
      _rankingAte[index] = actual.copyWith(
        reconocimientos: actual.reconocimientos + 1,
      );
    }
  }

  @override
  Future<void> reportarContenido(String tipo, String id, String motivo) async {
    // Registra reporte para revisión
  }
}
