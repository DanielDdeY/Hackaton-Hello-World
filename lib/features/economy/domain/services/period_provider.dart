import 'package:flutter/foundation.dart';

/// Bandera para habilitar herramientas ocultas de demostración (R12).
/// Activa por defecto en modo debug o mediante `--dart-define=ENABLE_DEMO_TOOLS=true`.
const bool kEnableDemoTools =
    kDebugMode ||
        bool.fromEnvironment('ENABLE_DEMO_TOOLS', defaultValue: false);

abstract interface class PeriodProvider {
  String get currentPeriod;
}

final class SystemPeriodProvider implements PeriodProvider {
  SystemPeriodProvider({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  String get currentPeriod {
    final lima = _clock().toUtc().subtract(const Duration(hours: 5));
    return '${lima.year}-${lima.month.toString().padLeft(2, '0')}';
  }
}

final class FakePeriodProvider implements PeriodProvider {
  FakePeriodProvider(this.currentPeriod);

  @override
  String currentPeriod;
}

/// Proveedor conmutable para el simulador de nuevo mes (solo lectura).
/// Mientras `isSimulating` es `true`, expone el periodo de un `FakePeriodProvider`
/// sin escribir jamás ese periodo en Firestore.
final class SimulatablePeriodProvider extends ChangeNotifier
    implements PeriodProvider {
  SimulatablePeriodProvider({PeriodProvider? base})
      : _base = base ?? SystemPeriodProvider();

  final PeriodProvider _base;
  FakePeriodProvider? _simulated;

  bool get isSimulating => _simulated != null;

  String get realPeriod => _base.currentPeriod;

  @override
  String get currentPeriod => _simulated?.currentPeriod ?? _base.currentPeriod;

  void simulateNextMonth() {
    _simulated = FakePeriodProvider(nextMonthPeriod(_base.currentPeriod));
    notifyListeners();
  }

  void clearSimulation() {
    if (_simulated == null) return;
    _simulated = null;
    notifyListeners();
  }

  void toggleNextMonthSimulation() {
    if (isSimulating) {
      clearSimulation();
    } else {
      simulateNextMonth();
    }
  }
}

String nextMonthPeriod(String period) {
  final parts = period.split('-');
  if (parts.length != 2) return period;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) return period;
  final nextYear = month == 12 ? year + 1 : year;
  final nextMonth = month == 12 ? 1 : month + 1;
  return '$nextYear-${nextMonth.toString().padLeft(2, '0')}';
}

bool needsMonthlyReset(String stored, String current) =>
    stored.isEmpty || stored.compareTo(current) < 0;