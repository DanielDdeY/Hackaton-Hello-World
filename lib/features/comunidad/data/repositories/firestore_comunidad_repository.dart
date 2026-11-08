import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../fixtures/datos_simulados_ate.dart';
import '../../domain/entities/evento_comunitario.dart';
import '../../domain/entities/favor.dart';
import '../../domain/entities/vecino_ranking.dart';
import '../../domain/repositories/comunidad_repository.dart';

/// Implementación real del repositorio conectado a Google Cloud Firestore.
class FirestoreComunidadRepository implements ComunidadRepository {
  FirestoreComunidadRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String usuarioActualId = 'usr_actual',
    this.usuarioActualNombre = 'Vecino Activo',
    this.distritoPorDefecto = 'Ate',
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth, // ignore: prefer_initializing_formals
       _usuarioActualIdFallback = usuarioActualId;

  final FirebaseFirestore _firestore;
  final FirebaseAuth? _auth;
  final String _usuarioActualIdFallback;
  final String usuarioActualNombre;
  final String distritoPorDefecto;

  @override
  String get usuarioActualId =>
      _auth?.currentUser?.uid ?? _usuarioActualIdFallback;

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
  Future<String> obtenerDistritoActual() async {
    final uid = usuarioActualId;
    if (uid.isNotEmpty) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        final distrito = (doc.data()?['district'] as String?)?.trim() ?? '';
        if (distrito.isNotEmpty) return distrito;
      } on FirebaseException {
        // Si el perfil no se puede leer, se usa el distrito demo.
      }
    }
    return distritoPorDefecto;
  }

  @override
  Future<List<VecinoRanking>> obtenerRanking({
    String ambito = 'distrito',
  }) async {
    final distrito = await obtenerDistritoActual();
    final slug = _distritoSlug(distrito);
    final snapshot = await _firestore
        .collection('ranking')
        .doc(slug)
        .collection('posiciones')
        .orderBy('xpPeriodo', descending: true)
        .limit(50)
        .get();

    var ranking = snapshot.docs
        .map((doc) => _mapearRanking(doc, distrito))
        .toList();

    if (ranking.isEmpty) {
      ranking = await _rankingDesdeUsuarios(distrito);
    }

    if (ranking.isEmpty && slug == 'ate' && _demoSeedingAllowed) {
      try {
        await sembrarDatosSimulados();
        final nuevoSnapshot = await _firestore
            .collection('ranking')
            .doc(slug)
            .collection('posiciones')
            .orderBy('xpPeriodo', descending: true)
            .limit(50)
            .get();
        ranking = nuevoSnapshot.docs
            .map((doc) => _mapearRanking(doc, distrito))
            .toList();
        if (ranking.isEmpty) {
          ranking = await _rankingDesdeUsuarios(distrito);
        }
      } catch (e) {
        debugPrint('No se pudo sembrar/leer datos simulados de Firestore: $e');
      }
    }

    return _incluirUsuarioActual(ranking);
  }

  @override
  Future<VecinoPerfil?> obtenerVecino(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();
    if (!document.exists) {
      final distrito = await obtenerDistritoActual();
      final slug = _distritoSlug(distrito);
      final posicionDoc = await _firestore
          .collection('ranking')
          .doc(slug)
          .collection('posiciones')
          .doc(uid)
          .get();
      if (!posicionDoc.exists) return null;
      final ranking = _mapearRanking(posicionDoc, distrito);
      return VecinoPerfil.desdeRanking(ranking);
    }

    final data = document.data()!;
    final distrito = (data['district'] as String?)?.trim();
    final distritoPerfil = distrito == null || distrito.isEmpty
        ? await obtenerDistritoActual()
        : distrito;
    final slug = _distritoSlug(distritoPerfil);
    final posicionDoc = await _firestore
        .collection('ranking')
        .doc(slug)
        .collection('posiciones')
        .doc(uid)
        .get();
    final posicionData = posicionDoc.data() ?? const <String, dynamic>{};
    final ranking = _vecinoDesdeUsuario(
      uid,
      data,
      distritoFallback: distritoPerfil,
      posicion: _int(posicionData['posicion'] ?? data['posicion']),
    );

    return VecinoPerfil(
      uid: uid,
      nombre: ranking.nombre,
      iniciales: ranking.iniciales,
      rol: (data['role'] as String?)?.trim().isNotEmpty == true
          ? data['role'] as String
          : 'Vecino',
      bio: ranking.bio,
      distrito: ranking.distrito,
      provincia: (data['province'] as String?) ?? '',
      departamento: (data['department'] as String?) ?? '',
      xpTotal: ranking.xpTotal,
      xpPeriodo: ranking.xpPeriodo,
      nivel: ranking.nivel,
      estrellas: ranking.estrellas,
      favoresCompletados: ranking.favoresCompletados,
      eventosAsistidos: ranking.eventosAsistidos,
      reconocimientos: ranking.reconocimientos,
      rachaSemanal: ranking.rachaSemanal,
      insignias: ranking.insignias,
      posicion: ranking.posicion,
      esUsuarioActual: uid == usuarioActualId,
      tendencia: ranking.tendencia,
    );
  }

  Future<List<VecinoRanking>> _rankingDesdeUsuarios(String distrito) async {
    final slug = _distritoSlug(distrito);
    final snapshot = await _firestore.collection('users').where('profileVersion', isEqualTo: 1).limit(100).get();
    final vecinos = <VecinoRanking>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      final distritoUsuario = (data['district'] as String?)?.trim() ?? '';
      if (distritoUsuario.isNotEmpty && _distritoSlug(distritoUsuario) != slug) {
        continue;
      }
      vecinos.add(
        _vecinoDesdeUsuario(
          document.id,
          data,
          distritoFallback: distritoUsuario.isEmpty ? distrito : distritoUsuario,
        ),
      );
    }
    vecinos.sort((a, b) {
      final byXp = b.xpPeriodo.compareTo(a.xpPeriodo);
      return byXp != 0 ? byXp : a.nombre.compareTo(b.nombre);
    });
    return _renumerar(vecinos);
  }

  Future<List<VecinoRanking>> _incluirUsuarioActual(
    List<VecinoRanking> ranking,
  ) async {
    final uid = usuarioActualId;
    if (uid.isEmpty || ranking.any((vecino) => vecino.uid == uid)) {
      return ranking;
    }

    Map<String, dynamic> data = const {};
    try {
      final document = await _firestore.collection('users').doc(uid).get();
      data = document.data() ?? const {};
    } on FirebaseException {
      // Se agrega al usuario actual con los datos disponibles en memoria.
    }

    final vecino = _vecinoDesdeUsuario(
      uid,
      {
        ...data,
        if ((data['name'] as String?)?.trim().isEmpty ?? true)
          'name': usuarioActualNombre,
      },
      distritoFallback: await obtenerDistritoActual(),
    );
    final actualizado = [...ranking, vecino]
      ..sort((a, b) {
        final byXp = b.xpPeriodo.compareTo(a.xpPeriodo);
        return byXp != 0 ? byXp : a.nombre.compareTo(b.nombre);
      });
    return _renumerar(actualizado);
  }

  @override
  Future<BuenVecinoSemana?> obtenerBuenVecinoSemana() async {
    final distrito = await obtenerDistritoActual();
    final slug = _distritoSlug(distrito);
    final doc = await _firestore
        .collection('stats')
        .doc(slug)
        .collection('buenVecino')
        .doc('actual')
        .get();
    if (!doc.exists) {
      final ranking = await obtenerRanking();
      if (ranking.isEmpty) return null;
      final primero = ranking.first;
      return BuenVecinoSemana(
        uid: primero.uid,
        nombre: primero.nombre,
        iniciales: primero.iniciales,
        distrito: primero.distrito,
        motivo: 'Reconocido por su ayuda constante en el distrito.',
        votosReconocimiento: primero.reconocimientos,
      );
    }
    final data = doc.data()!;
    return BuenVecinoSemana(
      uid: (data['uid'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      iniciales: (data['iniciales'] as String?) ?? 'BV',
      distrito:
          (data['distrito'] as String?)?.trim().isNotEmpty == true
          ? data['distrito'] as String
          : distrito,
      motivo: (data['motivo'] as String?) ?? '',
      votosReconocimiento: _int(data['votosReconocimiento']),
    );
  }

  /// Siembra en Firestore los datos simulados de Ate tanto en la rama 'ranking'
  /// como en la rama 'users' para que cada vecino tenga su información completa.
  bool get _demoSeedingAllowed => kDebugMode &&
      const bool.fromEnvironment('ENABLE_DEMO_SEED') &&
      _firestore.app.options.projectId == 'demo-hackaton-hello-world';

  Future<void> sembrarDatosSimulados({bool forzar = false}) async {
    if (!_demoSeedingAllowed) return;
    const slug = 'ate';
    final rankCol = _firestore
        .collection('ranking')
        .doc(slug)
        .collection('posiciones');
    final usersCol = _firestore.collection('users');

    if (!forzar) {
      try {
        final existing = await rankCol.limit(1).get();
        if (existing.docs.isNotEmpty) return;
      } on FirebaseException catch (e) {
        debugPrint('Verificación de siembra omitida: ${e.code}');
      }
    }

    final batch = _firestore.batch();
    for (var i = 0; i < datosSimuladosAte.length; i++) {
      final seed = datosSimuladosAte[i];
      final posicion = i + 1;
      final rankRef = rankCol.doc(seed.uid);
      batch.set(rankRef, seed.toRankingMap(posicion), SetOptions(merge: true));

      final userRef = usersCol.doc(seed.uid);
      batch.set(userRef, {
        ...seed.toUserMap(),
        'posicion': posicion,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final buenVecinoRef = _firestore
        .collection('stats')
        .doc(slug)
        .collection('buenVecino')
        .doc('actual');
    batch.set(buenVecinoRef, buenVecinoAteSeed, SetOptions(merge: true));

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      debugPrint('No se pudo guardar la siembra de datos simulados: ${e.code}');
    }
  }

  @override
  Future<void> nominarBuenVecino(String destinoUid, String motivo) async {
    final batch = _firestore.batch();
    final recRef = _firestore.collection('reconocimientos').doc();
    batch.set(recRef, {
      'autorId': usuarioActualId,
      'destinoId': destinoUid,
      'motivo': motivo,
      'fecha': FieldValue.serverTimestamp(),
    });

    final userRef = _firestore.collection('users').doc(destinoUid);
    batch.set(userRef, {
      'stats': {
        'reconocimientos': FieldValue.increment(1),
      },
      'reconocimientos': FieldValue.increment(1),
    }, SetOptions(merge: true));

    final distrito = await obtenerDistritoActual();
    final slug = _distritoSlug(distrito);
    final rankRef = _firestore
        .collection('ranking')
        .doc(slug)
        .collection('posiciones')
        .doc(destinoUid);
    batch.set(rankRef, {
      'reconocimientos': FieldValue.increment(1),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      debugPrint('No se pudo enviar reconocimiento completo: ${e.code}');
    }
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

  VecinoRanking _mapearRanking(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String distrito,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final nombre = (data['nombre'] as String?)?.trim().isNotEmpty == true
        ? data['nombre'] as String
        : 'Vecino';
    return VecinoRanking(
      uid: doc.id,
      nombre: nombre,
      iniciales:
          (data['iniciales'] as String?)?.trim().isNotEmpty == true
          ? data['iniciales'] as String
          : _iniciales(nombre),
      distrito:
          (data['distrito'] as String?)?.trim().isNotEmpty == true
          ? data['distrito'] as String
          : distrito,
      xpPeriodo: _int(data['xpPeriodo']),
      posicion: _int(data['posicion']),
      nivel: _int(data['nivel']),
      esUsuarioActual: doc.id == usuarioActualId,
      bio: (data['bio'] as String?) ?? '',
      insignias: _listaTexto(data['insignias'] ?? data['badges']),
      favoresCompletados: _int(data['favoresCompletados']),
      estrellas: _int(data['estrellas']),
      eventosAsistidos: _int(data['eventosAsistidos']),
      reconocimientos: _int(data['reconocimientos']),
      rachaSemanal: _int(data['rachaSemanal']),
      tendencia: VecinoRanking.tendenciaDesde(data['tendencia']),
      xpTotal: _int(data['xpTotal'] ?? data['xp']),
    );
  }

  VecinoRanking _vecinoDesdeUsuario(
    String uid,
    Map<String, dynamic> data, {
    required String distritoFallback,
    int posicion = 0,
  }) {
    final nombre = (data['name'] as String?)?.trim().isNotEmpty == true
        ? data['name'] as String
        : 'Vecino';
    final stats = data['stats'] is Map
        ? Map<String, dynamic>.from(data['stats'] as Map)
        : const <String, dynamic>{};
    final xpTotal = _int(data['xp']);
    final xpPeriodo = _int(
      data['weeklyXp'] ?? data['xpPeriodo'] ?? data['xpSemanal'],
    );
    final distrito = (data['district'] as String?)?.trim();
    return VecinoRanking(
      uid: uid,
      nombre: nombre,
      iniciales:
          (data['iniciales'] as String?)?.trim().isNotEmpty == true
          ? data['iniciales'] as String
          : _iniciales(nombre),
      distrito: distrito == null || distrito.isEmpty
          ? distritoFallback
          : distrito,
      xpPeriodo: xpPeriodo,
      posicion: posicion,
      nivel: _int(data['level'] ?? xpTotal ~/ 100),
      esUsuarioActual: uid == usuarioActualId,
      bio: (data['bio'] as String?) ?? '',
      insignias: _listaTexto(data['badges'] ?? data['insignias']),
      favoresCompletados: _int(
        stats['favoresCompletados'] ??
            data['favoresCompletados'] ??
            data['favors'],
      ),
      estrellas: _int(stats['estrellas'] ?? data['stars']),
      eventosAsistidos: _int(
        stats['eventosAsistidos'] ?? data['eventosAsistidos'],
      ),
      reconocimientos: _int(
        stats['reconocimientos'] ?? data['reconocimientos'],
      ),
      rachaSemanal: _int(stats['rachaSemanal'] ?? data['rachaSemanal']),
      tendencia: VecinoRanking.tendenciaDesde(data['tendencia']),
      xpTotal: xpTotal,
    );
  }

  List<VecinoRanking> _renumerar(List<VecinoRanking> ranking) {
    return [
      for (var index = 0; index < ranking.length; index++)
        ranking[index].copyWith(
          posicion: index + 1,
          esUsuarioActual: ranking[index].uid == usuarioActualId,
        ),
    ];
  }

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  static List<String> _listaTexto(Object? value) {
    if (value is Iterable) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String _iniciales(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .take(2)
        .map((parte) => parte.substring(0, 1).toUpperCase())
        .join();
    return partes.isEmpty ? 'V' : partes;
  }

  static String _distritoSlug(String distrito) {
    const conAcento = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const sinAcento = 'aaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (final rune in distrito.trim().toLowerCase().runes) {
      final caracter = String.fromCharCode(rune);
      final indice = conAcento.indexOf(caracter);
      buffer.write(indice >= 0 ? sinAcento[indice] : caracter);
    }
    final slug = buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'ate' : slug;
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
