import 'package:flutter/material.dart';

/// Paleta de colores compartida de la app.
///
/// Extraída de `main.dart` para que todas las secciones (features)
/// puedan usar los mismos colores sin importar archivos privados.
abstract final class AppColors {
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF006D77);
  static const text = Color(0xFF1A1A1A);
  static const secondaryText = Color(0xFF5C5C5C);

  static const navigationLabel = TextStyle(
    color: text,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}
