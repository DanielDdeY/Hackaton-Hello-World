import 'package:flutter/material.dart';

import '../models/emergency_contact.dart';

/// Directorio de emergencia de Perú — datos embebidos, disponibles offline.
///
/// Fuente: gob.pe/547-telefonos-de-emergencia y Pronatel/MTC (2026).
/// Nota: el 911 aún está en fase de pruebas (solo Lima Metropolitana y
/// Callao); la construcción de la central culmina en dic. 2026 y entra
/// en operación prevista para el 2T 2027.
abstract final class PeruEmergencyNumbers {
  static const List<EmergencyContact> contacts = [
    EmergencyContact(
      name: 'Brigada Vecinal',
      icon: Icons.groups_outlined,
      description: 'Se conectará con tu grupo',
      isNational: false,
    ),
    EmergencyContact(
      name: 'Bomberos',
      phoneNumber: '116',
      icon: Icons.local_fire_department_outlined,
      description: 'Incendios y rescates',
    ),
    EmergencyContact(
      name: 'Primeros Auxilios (SAMU)',
      phoneNumber: '106',
      icon: Icons.medical_services_outlined,
      description: 'Ambulancias y urgencias médicas',
    ),
    EmergencyContact(
      name: 'Policía Nacional',
      phoneNumber: '105',
      icon: Icons.local_police_outlined,
      description: 'Seguridad ciudadana',
    ),
    EmergencyContact(
      name: 'Defensa Civil',
      phoneNumber: '115',
      icon: Icons.tsunami_outlined,
      description: 'Desastres y evacuaciones',
    ),
    EmergencyContact(
      name: 'Línea 100 (violencia)',
      phoneNumber: '100',
      icon: Icons.shield_outlined,
      description: 'Violencia familiar y sexual',
    ),
    EmergencyContact(
      name: 'Infosalud',
      phoneNumber: '113',
      icon: Icons.health_and_safety_outlined,
      description: 'Información de salud',
    ),
    EmergencyContact(
      name: 'EsSalud',
      phoneNumber: '117',
      icon: Icons.local_hospital_outlined,
      description: 'Emergencias médicas de asegurados',
    ),
    EmergencyContact(
      name: 'Policía de Carreteras',
      phoneNumber: '110',
      icon: Icons.add_road_outlined,
      description: 'Accidentes en vías',
    ),
    EmergencyContact(
      name: 'Cruz Roja Peruana',
      phoneNumber: '01 266 0481',
      icon: Icons.volunteer_activism_outlined,
      description: 'Asistencia humanitaria',
    ),
    EmergencyContact(
      name: 'Emergencias 911 (Lima/Callao)',
      phoneNumber: '911',
      icon: Icons.emergency_outlined,
      description: 'Número único — en fase de pruebas',
    ),
  ];
}
