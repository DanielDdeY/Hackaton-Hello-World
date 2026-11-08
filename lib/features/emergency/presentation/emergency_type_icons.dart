import 'package:flutter/material.dart';

import '../domain/emergency_type_labels.dart';

/// Icono que representa un tipo de emergencia en el mapa.
///
/// Usa la etiqueta central para tolerar nombres del enum, datos antiguos y
/// valores escritos directamente en español.
IconData emergencyTypeIcon(String? raw) {
  return switch (emergencyTypeLabel(raw)) {
    'ROBO' => Icons.masks_rounded,
    'ACCIDENTE' => Icons.car_crash_rounded,
    'DESASTRE' => Icons.crisis_alert_rounded,
    'SALUD' => Icons.medical_services_rounded,
    'INCENDIO' => Icons.local_fire_department_rounded,
    'INUNDACIÓN' => Icons.flood_rounded,
    'PERSONA DESAPARECIDA' => Icons.person_search_rounded,
    'OTRO' || 'EMERGENCIA' => Icons.sos_rounded,
    _ => Icons.warning_amber_rounded,
  };
}
