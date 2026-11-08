import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/mascota.dart';
import '../../domain/repositories/mascota_repository.dart';
import '../../domain/services/caja_sorpresas_service.dart';

/// Repositorio local para la mascota basado en SharedPreferences.
class LocalMascotaRepository implements MascotaRepository {
  LocalMascotaRepository({
    required SharedPreferences preferences,
    CajaSorpresasService? cajaService,
  })  : _prefs = preferences,
        _cajaService = cajaService ?? CajaSorpresasService();

  final SharedPreferences _prefs;
  final CajaSorpresasService _cajaService;
  final _controladores = <String, StreamController<Mascota>>{};

  StreamController<Mascota> _controladorPara(String uid) {
    return _controladores.putIfAbsent(
      uid,
      () => StreamController<Mascota>.broadcast(),
    );
  }

  String _clave(String uid, String campo) => 'mascota_${campo}_$uid';

  @override
  Future<Mascota> obtenerMascota(String uid) async {
    final nombre = _prefs.getString(_clave(uid, 'nombre')) ?? 'Mi Cuy';
    final equipado = _prefs.getString(_clave(uid, 'equipado'));
    final itemsRaw = _prefs.getString(_clave(uid, 'items'));
    final pity = _prefs.getInt(_clave(uid, 'pity')) ?? 0;
    final primeraGratis = _prefs.getBool(_clave(uid, 'primera_gratis')) ?? true;
    final cajasTotal = _prefs.getInt(_clave(uid, 'cajas_total')) ?? 0;

    List<String> items = const [];
    if (itemsRaw != null && itemsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(itemsRaw);
        if (decoded is List) {
          items = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return Mascota(
      nombre: nombre,
      itemEquipadoId: equipado,
      itemsDesbloqueados: items,
      pityCount: pity,
      primeraCajaGratis: primeraGratis,
      cajasAbiertasTotal: cajasTotal,
    );
  }

  @override
  Stream<Mascota> escucharMascota(String uid) async* {
    yield await obtenerMascota(uid);
    yield* _controladorPara(uid).stream;
  }

  Future<void> _guardarYNotificar(String uid, Mascota mascota) async {
    await _prefs.setString(_clave(uid, 'nombre'), mascota.nombre);
    if (mascota.itemEquipadoId != null) {
      await _prefs.setString(_clave(uid, 'equipado'), mascota.itemEquipadoId!);
    } else {
      await _prefs.remove(_clave(uid, 'equipado'));
    }
    await _prefs.setString(_clave(uid, 'items'), jsonEncode(mascota.itemsDesbloqueados));
    await _prefs.setInt(_clave(uid, 'pity'), mascota.pityCount);
    await _prefs.setBool(_clave(uid, 'primera_gratis'), mascota.primeraCajaGratis);
    await _prefs.setInt(_clave(uid, 'cajas_total'), mascota.cajasAbiertasTotal);

    _controladorPara(uid).add(mascota);
  }

  @override
  Future<void> actualizarNombre(String uid, String nuevoNombre) async {
    final actual = await obtenerMascota(uid);
    final actualizada = actual.copyWith(nombre: nuevoNombre.trim());
    await _guardarYNotificar(uid, actualizada);
  }

  @override
  Future<void> equiparItem(String uid, String? itemId) async {
    final actual = await obtenerMascota(uid);
    final actualizada = actual.copyWith(
      itemEquipadoId: itemId,
      desequipar: itemId == null,
    );
    await _guardarYNotificar(uid, actualizada);
  }

  @override
  Future<ResultadoAperturaCaja> abrirCaja({
    required String uid,
    required int fichasDisponibles,
  }) async {
    final actual = await obtenerMascota(uid);
    final resultado = _cajaService.abrirCaja(
      mascota: actual,
      fichasDisponibles: fichasDisponibles,
    );
    await _guardarYNotificar(uid, resultado.mascotaActualizada);
    return resultado;
  }
}
