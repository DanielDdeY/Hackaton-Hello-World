import 'package:flutter/material.dart';

const _background = Color(0xFFFAFAFA);
const _surface = Color(0xFFFFFFFF);
const _primary = Color(0xFF006D77);
const _text = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF5C5C5C);

ThemeData createAppTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: _primary,
    primary: _primary,
    onPrimary: _surface,
    surface: _surface,
    onSurface: _text,
    onSurfaceVariant: _secondaryText,
  );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: colors,
    scaffoldBackgroundColor: _background,
  );
  final text = base.textTheme;
  final buttonText = text.labelLarge?.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  return base.copyWith(
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarThemeData(backgroundColor: _background),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: _surface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: _surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0x0D000000),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(textStyle: buttonText),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(textStyle: buttonText),
    ),
  );
}
