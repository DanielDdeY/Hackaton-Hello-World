import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/evento_comunitario.dart';
import '../../domain/entities/favor.dart';
import '../../domain/entities/vecino_ranking.dart';
import '../../domain/repositories/comunidad_repository.dart';

/// Implementación real del repositorio conectado a Google Cloud Firestore.
class FirestoreComunidadRepository implements ComunidadRepository {
  FirestoreComunidadRepository({
    FirebaseFirestore? firestore,
    this.usuarioActualId = 'usr_actual',
    this.usuarioActualNombre = 'Vecino Activo',
    this.cuadraId = 'cuadra_los_pinos_3',
    this.barrioId = 'barrio_sector_2',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  @override
  final String usuarioActualId;
  final String usuarioActualNombre;
  final String cuadraId;
  final String barrioId;

  // Colecciones según la especificación de docs/comunidad-ayuda.md
  CollectionReference<Map<String, dynamic>> get _favoresCol => _firestore.collection('favores');
  CollectionReference<Map<String, dynamic>> get _eventosCol => _firestore.collection('eventos');
  CollectionReference<Map<String, dynamic>> get _reportesCol => _firestore.collection('reportes');

  @override
  Future<List<Favor>> obtenerFavores({
    CategoriaFavor? categoria,
    TamanoFavor? tamano,
    bool soloConCupo = false,
  }) async {
    Query<Map<String, dynamic>> query = _favoresCol.orderBy('creadoEn', descending: true);

    if (categoria != null) {
      query = query.where('categoria', isEqualTo: categoria.name);
    }
    if (tamano != null) {
      query = query.where('tamano', isEqualTo: tamano.name);
    }

    final snapshot = await query.get();
    final favores = snapshot.docs.map(_mapearFavor).toList();

    if (soloConCupo) {
      return favores.where((f) => f.tieneCupo).toList();
    }
    return favores;
  }

  @override
  Future<Favor> obtenerFavorPorId(String id) async {
    final doc = await _favoresCol.doc(id).get();
    if (!doc.exists) {
      throw Exception('Favor no encontrado');
    }
    return _mapearFavor(doc);
  }

  @override
  Future<Favor> agregarFavor(Favor favor) async {
    final docRef = _favoresCol.doc(favor.id);
    await docRef.set({
      'titulo': favor.titulo,
      'descripcion': favor.descripcion,
      'categoria': favor.categoria.name,
      'tamano': favor.tamano.name,
      'estado': favor.estado.name,
      'cuposTotales': favor.cuposTotales,
      'cuposTomados': favor.cuposTomados,
      'solicitanteId': favor.solicitanteId,
      'solicitanteNombre': favor.solicitanteNombre,
      'solicitanteTelefono': favor.solicitanteTelefono,
      'cuadraNombre': favor.cuadraNombre,
      'ubicacionAproximada': favor.ubicacionAproximada,
      'ubicacionExacta': favor.ubicacionExacta,
      'creadoEn': Timestamp.fromDate(favor.creadoEn),
      'venceEn': Timestamp.fromDate(favor.venceEn),
      'monedasRecompensa': favor.monedasRecompensa,
      'xpRecompensa': favor.xpRecompensa,
    });
    return favor;
  }

  @override
  Future<void> aceptarFavor(String favorId) async {
    final docRef = _favoresCol.doc(favorId);

    // Transacción atómica en Firestore para garantizar respeto estricto de cupos (RNF-05)
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('El favor no existe');

      final data = snapshot.data()!;
      final cuposTotales = data['cuposTotales'] as int? ?? 1;
      final cuposTomados = data['cuposTomados'] as int? ?? 0;

      if (cuposTomados >= cuposTotales) {
        throw Exception('Cupos agotados');
      }

      final nuevoTomados = cuposTomados + 1;
      final nuevoEstado = nuevoTomados >= cuposTotales ? 'cuposLlenos' : 'enCurso';

      transaction.update(docRef, {
        'cuposTomados': nuevoTomados,
        'estado': nuevoEstado,
      });

      // Registra al participante en la subcolección correspondiente
      final partRef = docRef.collection('participantes').doc(usuarioActualId);
      transaction.set(partRef, {
        'uid': usuarioActualId,
        'nombre': usuarioActualNombre,
        'estado': 'enCurso',
        'aceptadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> marcarTerminado(String favorId) async {
    final docRef = _favoresCol.doc(favorId);
    final partRef = docRef.collection('participantes').doc(usuarioActualId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(docRef, {'estado': 'esperandoConfirmacion'});
      transaction.update(partRef, {
        'estado': 'terminado',
        'terminadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> confirmarYCalificar(String favorId, double calificacion) async {
    final docRef = _favoresCol.doc(favorId);
    await docRef.update({
      'estado': 'completado',
      'calificacion': calificacion,
      'confirmadoEn': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<EventoComunitario>> obtenerEventos() async {
    final snapshot = await _eventosCol.orderBy('fecha').get();
    return snapshot.docs.map(_mapearEvento).toList();
  }

  @override
  Future<void> responderEvento(String eventoId, RespuestaEvento respuesta) async {
    final docRef = _eventosCol.doc(eventoId);
    final asistenciaRef = docRef.collection('asistencias').doc(usuarioActualId);

    await asistenciaRef.set({
      'respuesta': respuesta.name,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> verificarAsistencia(String eventoId, String codigo) async {
    final asistenciaRef = _eventosCol.doc(eventoId).collection('asistencias').doc(usuarioActualId);
    await asistenciaRef.set({
      'respuesta': 'voy',
      'verificada': true,
      'codigoValidado': codigo,
      'verificadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<VecinoRanking>> obtenerRanking({String ambito = 'cuadra'}) async {
    // Consulta precalculada desde la colección de rankings (RN-14 / RN-15)
    final snapshot = await _firestore.collection('ranking').doc(ambito).collection('posiciones').limit(20).get();

    if (snapshot.docs.isEmpty) {
      return [
        VecinoRanking(
          uid: usuarioActualId,
          nombre: usuarioActualNombre,
          iniciales: 'TÚ',
          cuadraNombre: 'Cdra. 3',
          xpPeriodo: 180,
          posicion: 1,
          nivel: 6,
          esUsuarioActual: true,
        ),
      ];
    }

    return snapshot.docs.map((d) {
      final data = d.data();
      return VecinoRanking(
        uid: d.id,
        nombre: data['nombre'] ?? 'Vecino',
        iniciales: data['iniciales'] ?? 'V',
        cuadraNombre: data['cuadraNombre'] ?? '',
        xpPeriodo: data['xpPeriodo'] ?? 0,
        posicion: data['posicion'] ?? 1,
        nivel: data['nivel'] ?? 1,
        esUsuarioActual: d.id == usuarioActualId,
      );
    }).toList();
  }

  @override
  Future<BuenVecinoSemana?> obtenerBuenVecinoSemana() async {
    final doc = await _firestore.collection('stats').doc(barrioId).collection('buenVecino').doc('actual').get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return BuenVecinoSemana(
      uid: data['uid'] ?? '',
      nombre: data['nombre'] ?? '',
      iniciales: data['iniciales'] ?? 'BV',
      cuadraNombre: data['cuadraNombre'] ?? '',
      motivo: data['motivo'] ?? '',
      votosReconocimiento: data['votosReconocimiento'] ?? 0,
    );
  }

  @override
  Future<void> nominarBuenVecino(String destinoUid, String motivo) async {
    await _firestore.collection('reconocimientos').add({
      'autorId': usuarioActualId,
      'destinoId': destinoUid,
      'motivo': motivo,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> reportarContenido(String tipo, String id, String motivo) async {
    await _reportesCol.add({
      'tipo': tipo,
      'referenciaId': id,
      'motivo': motivo,
      'reportadoPor': usuarioActualId,
      'fecha': FieldValue.serverTimestamp(),
      'estado': 'enRevision',
    });
  }

  // Mapeos auxiliares DTO -> Entidad
  Favor _mapearFavor(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Favor(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      categoria: CategoriaFavor.values.firstWhere(
        (c) => c.name == data['categoria'],
        orElse: () => CategoriaFavor.otros,
      ),
      tamano: TamanoFavor.values.firstWhere(
        (t) => t.name == data['tamano'],
        orElse: () => TamanoFavor.medio,
      ),
      estado: EstadoFavor.values.firstWhere(
        (e) => e.name == data['estado'],
        orElse: () => EstadoFavor.abierto,
      ),
      cuposTotales: data['cuposTotales'] ?? 1,
      cuposTomados: data['cuposTomados'] ?? 0,
      solicitanteId: data['solicitanteId'] ?? '',
      solicitanteNombre: data['solicitanteNombre'] ?? '',
      solicitanteTelefono: data['solicitanteTelefono'] ?? '',
      cuadraNombre: data['cuadraNombre'] ?? '',
      ubicacionAproximada: data['ubicacionAproximada'] ?? '',
      ubicacionExacta: data['ubicacionExacta'],
      creadoEn: (data['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      venceEn: (data['venceEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      monedasRecompensa: data['monedasRecompensa'] ?? TamanoFavor.medio.monedasBase,
      xpRecompensa: data['xpRecompensa'] ?? TamanoFavor.medio.xpBase,
    );
  }

  EventoComunitario _mapearEvento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return EventoComunitario(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      tipo: TipoEvento.values.firstWhere(
        (t) => t.name == data['tipo'],
        orElse: () => TipoEvento.reunion,
      ),
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lugar: data['lugar'] ?? '',
      cuadraNombre: data['cuadraNombre'] ?? '',
      organizadorNombre: data['organizadorNombre'] ?? '',
      requiereAsistencia: data['requiereAsistencia'] ?? false,
      asistenciasVoy: data['asistenciasVoy'] ?? 0,
      asistenciasInteresa: data['asistenciasInteresa'] ?? 0,
    );
  }
}
