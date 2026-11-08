import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/emergency/presentation/emergency_type_icons.dart';

void main() {
  test('asigna un icono distinto a cada tipo de emergencia', () {
    expect(emergencyTypeIcon('robbery'), Icons.masks_rounded);
    expect(emergencyTypeIcon('accident'), Icons.car_crash_rounded);
    expect(emergencyTypeIcon('disaster'), Icons.crisis_alert_rounded);
    expect(emergencyTypeIcon('health'), Icons.medical_services_rounded);
    expect(emergencyTypeIcon('fire'), Icons.local_fire_department_rounded);
    expect(emergencyTypeIcon('flood'), Icons.flood_rounded);
    expect(emergencyTypeIcon('missingPerson'), Icons.person_search_rounded);
    expect(emergencyTypeIcon('other'), Icons.sos_rounded);
    expect(emergencyTypeIcon('emergency'), Icons.sos_rounded);
  });

  test('mantiene el icono de desastre para datos antiguos', () {
    expect(emergencyTypeIcon('tragedy'), Icons.crisis_alert_rounded);
    expect(emergencyTypeIcon('tragedia'), Icons.crisis_alert_rounded);
  });

  test('usa un icono de alerta para valores desconocidos', () {
    expect(emergencyTypeIcon('desconocido'), Icons.warning_amber_rounded);
    expect(emergencyTypeIcon(null), Icons.sos_rounded);
  });
}
