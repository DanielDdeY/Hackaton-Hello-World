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

  String _ambitoRanking = 'cuadra';
  String get ambitoRanking => _ambitoRanking;

  Future<void> cargarTodo() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([cargarRanking(_ambitoRanking), cargarBuenVecino()]);
    } catch (e) {
      _error = 'Ocurrió un inconveniente al cargar la información: $e';
    } finally {
      _cargando = false;
      notifyListeners();
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
