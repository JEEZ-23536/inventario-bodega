import 'package:flutter/material.dart';

/// Tema oscuro "industrial" para uso en bodega: alto contraste,
/// botones grandes y color de acento ambar (estilo senalizacion de almacen).
class AppTheme {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceAlt = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFFFFA000); // ambar industrial
  static const Color danger = Color(0xFFE53935); // faltante
  static const Color success = Color(0xFF43A047); // sobrante
  static const Color neutral = Color(0xFF9E9E9E); // sin contar

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: surface,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: surfaceAlt,
          disabledForegroundColor: Colors.white38,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: accent, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dividerColor: Colors.white12,
      tabBarTheme: const TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: Colors.white60,
        indicatorColor: accent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceAlt,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
