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
  late List<VecinoRanking> _rankingCuadra;
  late List<VecinoRanking> _rankingBarrio;
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

    _rankingCuadra = [
      const VecinoRanking(
        uid: 'usr_carmen',
        nombre: 'Carmen Rosa Díaz',
        iniciales: 'CR',
        cuadraNombre: 'Cdra. 3',
        xpPeriodo: 240,
        posicion: 1,
        nivel: 8,
      ),
      VecinoRanking(
        uid: usuarioActualId,
        nombre: usuarioActualNombre,
        iniciales: 'TÚ',
        cuadraNombre: 'Cdra. 3',
        xpPeriodo: 180,
        posicion: 2,
        nivel: 6,
        esUsuarioActual: true,
      ),
      const VecinoRanking(
        uid: 'usr_jorge',
        nombre: 'Jorge Mendoza',
        iniciales: 'JM',
        cuadraNombre: 'Cdra. 3',
        xpPeriodo: 150,
        posicion: 3,
        nivel: 5,
      ),
      const VecinoRanking(
        uid: 'usr_lucia',
        nombre: 'Lucía Fernández',
        iniciales: 'LF',
        cuadraNombre: 'Cdra. 3',
        xpPeriodo: 90,
        posicion: 4,
        nivel: 4,
      ),
    ];

    _rankingBarrio = [
      const VecinoRanking(
        uid: 'usr_roberto',
        nombre: 'Roberto Huamán',
        iniciales: 'RH',
        cuadraNombre: 'Sector 1',
        xpPeriodo: 380,
        posicion: 1,
        nivel: 12,
      ),
      const VecinoRanking(
        uid: 'usr_carmen',
        nombre: 'Carmen Rosa Díaz',
        iniciales: 'CR',
        cuadraNombre: 'Sector 2',
        xpPeriodo: 240,
        posicion: 2,
        nivel: 8,
      ),
      VecinoRanking(
        uid: usuarioActualId,
        nombre: usuarioActualNombre,
        iniciales: 'TÚ',
        cuadraNombre: 'Sector 2',
        xpPeriodo: 180,
        posicion: 3,
        nivel: 6,
        esUsuarioActual: true,
      ),
    ];

    _buenVecino = const BuenVecinoSemana(
      uid: 'usr_carmen',
      nombre: 'Doña Carmen Rosa',
      iniciales: 'CR',
      cuadraNombre: 'Calle Los Pinos Cdra. 3',
      motivo: 'Por coordinar la olla común de emergencia y cuidar a las mascotas de los vecinos durante el corte de luz.',
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
  Future<List<VecinoRanking>> obtenerRanking({String ambito = 'cuadra'}) async {
    return ambito == 'cuadra' ? _rankingCuadra : _rankingBarrio;
  }

  @override
  Future<BuenVecinoSemana?> obtenerBuenVecinoSemana() async {
    return _buenVecino;
  }

  @override
  Future<void> nominarBuenVecino(String destinoUid, String motivo) async {
    // Registra nominación local
  }

  @override
  Future<void> reportarContenido(String tipo, String id, String motivo) async {
    // Registra reporte para revisión
  }
}
