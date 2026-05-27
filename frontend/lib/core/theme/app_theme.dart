import 'package:flutter/material.dart';

/// Tema central de Rent App.
///
/// No busca ser una UI final.
/// Su objetivo estructural es evitar estilos dispersos por toda la app.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );
  }
}
