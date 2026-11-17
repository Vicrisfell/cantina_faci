import 'package:flutter/material.dart';

class AppColors {
  static const bege = Color(0xFFF5EBD6);
  static const bordo = Color(0xFF5E1914);
  static const bordoEscuro = Color(0xFF6E1D17);
  static const vermelhoToldo = Color(0xFF9E1B18);
  static const marrom = Color(0xFF3B2A20);
  static const branco = Color(0xFFFFFFFF);
  static const alerta = Color(0xFFB45309);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.bordoEscuro,
      primary: AppColors.bordoEscuro,
      secondary: AppColors.vermelhoToldo,
      surface: AppColors.branco,
      onSurface: AppColors.marrom,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bege,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEDF1F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.branco,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bordoEscuro,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
