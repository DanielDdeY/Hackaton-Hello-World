import 'package:flutter/material.dart';

/// Contacto de emergencia del directorio.
class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.icon,
    this.phoneNumber,
    this.description,
    this.isNational = true,
  });

  /// Nombre visible (ej. "Bomberos").
  final String name;

  /// Número marcable (ej. "116" o "01 266 0481").
  /// `null` cuando el dato vendrá después (ej. Brigada Vecinal desde Firestore).
  final String? phoneNumber;

  /// Ícono representativo.
  final IconData icon;

  /// Texto opcional bajo el nombre.
  final String? description;

  /// `true` si es un número nacional embebido (disponible offline).
  final bool isNational;

  /// `true` si hay número para marcar.
  bool get canCall => phoneNumber != null && phoneNumber!.isNotEmpty;

  /// URI para lanzar la llamada con `url_launcher`.
  Uri? get dialUri => canCall
      ? Uri(scheme: 'tel', path: phoneNumber!.replaceAll(' ', ''))
      : null;
}
