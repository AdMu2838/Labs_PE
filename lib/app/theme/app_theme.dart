import 'package:flutter/material.dart';

abstract final class UnsaColors {
  // Paleta inspirada en la identidad de la UNSA; editable en un único lugar.
  static const garnet = Color(0xFF7B1835);
  static const darkGarnet = Color(0xFF4C1026);
  static const gold = Color(0xFFC5A15B);
  static const canvas = Color(0xFFF7F5F2);
  static const ink = Color(0xFF25242B);
  static const muted = Color(0xFF6D6974);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: UnsaColors.garnet).copyWith(
    primary: UnsaColors.garnet, secondary: UnsaColors.gold,
    surface: Colors.white, onSurface: UnsaColors.ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: UnsaColors.canvas,
    fontFamily: 'Arial',
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
    cardTheme: CardThemeData(elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFECE7E2)))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDD7D2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDD7D2)))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
      headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -.5),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: UnsaColors.muted, height: 1.5)),
  );
}
