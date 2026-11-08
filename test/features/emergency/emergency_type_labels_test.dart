import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/emergency/domain/emergency_type_labels.dart';

void main() {
  test('traduce los tipos del enum a etiquetas en español', () {
    expect(emergencyTypeLabel('robbery'), 'ROBO');
    expect(emergencyTypeLabel('accident'), 'ACCIDENTE');
    expect(emergencyTypeLabel('disaster'), 'DESASTRE');
    expect(emergencyTypeLabel('tragedy'), 'DESASTRE');
    expect(emergencyTypeLabel('health'), 'SALUD');
    expect(emergencyTypeLabel('fire'), 'INCENDIO');
    expect(emergencyTypeLabel('flood'), 'INUNDACIÓN');
    expect(emergencyTypeLabel('missingPerson'), 'PERSONA DESAPARECIDA');
    expect(emergencyTypeLabel('other'), 'OTRO');
  });

  test('tolera valores antiguos o ya escritos en español', () {
    expect(emergencyTypeLabel('ROBO'), 'ROBO');
    expect(emergencyTypeLabel('Accidente'), 'ACCIDENTE');
    expect(emergencyTypeLabel('tragedia'), 'DESASTRE');
    expect(emergencyTypeLabel('desastre'), 'DESASTRE');
    expect(emergencyTypeLabel('emergencia'), 'EMERGENCIA');
    expect(emergencyTypeLabel(''), 'EMERGENCIA');
    expect(emergencyTypeLabel(null), 'EMERGENCIA');
    expect(emergencyTypeLabel('desconocido'), 'DESCONOCIDO');
  });
}
