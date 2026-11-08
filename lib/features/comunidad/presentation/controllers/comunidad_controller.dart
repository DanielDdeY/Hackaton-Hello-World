import 'package:flutter/foundation.dart';

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

  List<VecinoRanking> _ranking = [];
  List<VecinoRanking> get ranking => _ranking;

  BuenVecinoSemana? _buenVecino;
  BuenVecinoSemana? get buenVecino => _buenVecino;

  String _distritoRanking = 'Ate';
  String get distritoRanking => _distritoRanking;
  bool _distritoResuelto = false;
  bool get distritoResuelto => _distritoResuelto;

  static const ambitoRanking = 'distrito';

  Future<void> cargarTodo() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([cargarRanking(), cargarBuenVecino()]);
    } catch (e) {
      _error = 'Ocurrió un inconveniente al cargar la información: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarRanking() async {
    try {
      _distritoRanking = await repository.obtenerDistritoActual();
      _distritoResuelto = true;
      notifyListeners();
      _ranking = await repository.obtenerRanking(ambito: ambitoRanking);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo cargar el ranking: $e';
      notifyListeners();
    }
  }

  Future<VecinoPerfil?> cargarPerfilVecino(String uid) async {
    try {
      return await repository.obtenerVecino(uid);
    } catch (e) {
      _error = 'No se pudo cargar el perfil del vecino: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> cargarBuenVecino() async {
    try {
      _buenVecino = await repository.obtenerBuenVecinoSemana();
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo cargar el buen vecino: $e';
      notifyListeners();
    }
  }

  Future<void> nominarBuenVecino(String destinoUid, String motivo) async {
    try {
      await repository.nominarBuenVecino(destinoUid, motivo);
      await Future.wait([cargarRanking(), cargarBuenVecino()]);
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
