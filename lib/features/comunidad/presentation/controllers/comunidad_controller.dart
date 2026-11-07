import 'package:flutter/foundation.dart';

import '../../domain/entities/evento_comunitario.dart';
import '../../domain/entities/favor.dart';
import '../../domain/entities/resumen_hoy.dart';
import '../../domain/entities/vecino_ranking.dart';
import '../../domain/repositories/comunidad_repository.dart';

class ComunidadController extends ChangeNotifier {
  ComunidadController({required this.repository}) {
    cargarTodo();
  }

  final ComunidadRepository repository;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  ResumenHoy? _resumenHoy;
  ResumenHoy? get resumenHoy => _resumenHoy;

  List<Favor> _favores = [];
  List<Favor> get favores => _favores;

  List<EventoComunitario> _eventos = [];
  List<EventoComunitario> get eventos => _eventos;

  List<VecinoRanking> _ranking = [];
  List<VecinoRanking> get ranking => _ranking;

  BuenVecinoSemana? _buenVecino;
  BuenVecinoSemana? get buenVecino => _buenVecino;

  String _ambitoRanking = 'cuadra';
  String get ambitoRanking => _ambitoRanking;

  CategoriaFavor? _filtroCategoria;
  CategoriaFavor? get filtroCategoria => _filtroCategoria;

  TamanoFavor? _filtroTamano;
  TamanoFavor? get filtroTamano => _filtroTamano;

  bool _filtroSoloConCupo = false;
  bool get filtroSoloConCupo => _filtroSoloConCupo;

  Future<void> cargarTodo() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        cargarResumenHoy(),
        cargarFavores(),
        cargarEventos(),
        cargarRanking(_ambitoRanking),
        cargarBuenVecino(),
      ]);
    } catch (e) {
      _error = 'Ocurrió un inconveniente al cargar la información: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarResumenHoy() async {
    _resumenHoy = await repository.obtenerResumenHoy();
    notifyListeners();
  }

  Future<void> cargarFavores() async {
    _favores = await repository.obtenerFavores(
      categoria: _filtroCategoria,
      tamano: _filtroTamano,
      soloConCupo: _filtroSoloConCupo,
    );
    notifyListeners();
  }

  Future<void> setFiltrosFavores({
    CategoriaFavor? categoria,
    TamanoFavor? tamano,
    bool? soloConCupo,
  }) async {
    _filtroCategoria = categoria;
    _filtroTamano = tamano;
    if (soloConCupo != null) _filtroSoloConCupo = soloConCupo;
    await cargarFavores();
  }

  Future<void> aceptarFavor(String favorId) async {
    try {
      await repository.aceptarFavor(favorId);
      await cargarFavores();
      await cargarResumenHoy();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> marcarTerminado(String favorId) async {
    try {
      await repository.marcarTerminado(favorId);
      await cargarFavores();
      await cargarResumenHoy();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> confirmarYCalificar(String favorId, double calificacion) async {
    try {
      await repository.confirmarYCalificar(favorId, calificacion);
      await cargarFavores();
      await cargarResumenHoy();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cargarEventos() async {
    _eventos = await repository.obtenerEventos();
    notifyListeners();
  }

  Future<void> responderEvento(String eventoId, RespuestaEvento respuesta) async {
    try {
      await repository.responderEvento(eventoId, respuesta);
      await cargarEventos();
      await cargarResumenHoy();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cargarRanking(String ambito) async {
    _ambitoRanking = ambito;
    _ranking = await repository.obtenerRanking(ambito: ambito);
    notifyListeners();
  }

  Future<void> cargarBuenVecino() async {
    _buenVecino = await repository.obtenerBuenVecinoSemana();
    notifyListeners();
  }

  Future<void> nominarBuenVecino(String destinoUid, String motivo) async {
    try {
      await repository.nominarBuenVecino(destinoUid, motivo);
      await cargarRanking(_ambitoRanking);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}

