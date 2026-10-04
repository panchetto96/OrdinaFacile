import 'package:flutter/material.dart';

/// Colori e font presi da dofrellidistribuzione.it.
class Brand {
  static const bordeaux = Color(0xFF761413);
  static const bordeauxDark = Color(0xFF450D0C);
  static const green = Color(0xFF009A50);
  static const cream = Color(0xFFFBF7F4);

  static const bodyFont = 'Poppins';
  static const titleFont = 'JosefinSans';
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.bordeaux,
    primary: Brand.bordeaux,
    onPrimary: Colors.white,
    secondary: Brand.green,
    onSecondary: Colors.white,
    tertiary: Brand.green,
    surface: Colors.white,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: Brand.bodyFont);
  TextStyle? title(TextStyle? s) => s?.copyWith(fontFamily: Brand.titleFont, fontWeight: FontWeight.w700, color: Brand.bordeaux);
  final text = base.textTheme;
  return base.copyWith(
    scaffoldBackgroundColor: Brand.cream,
    textTheme: text.copyWith(
      displaySmall: title(text.displaySmall),
      headlineLarge: title(text.headlineLarge),
      headlineMedium: title(text.headlineMedium),
      headlineSmall: title(text.headlineSmall),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Brand.bordeaux,
      foregroundColor: Colors.white,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: Brand.titleFont, fontWeight: FontWeight.w700, fontSize: 22, color: Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Brand.bordeaux.withValues(alpha: 0.12),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Brand.green,
      foregroundColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontFamily: Brand.bodyFont, fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    cardTheme: const CardThemeData(color: Colors.white, surfaceTintColor: Colors.transparent),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}
