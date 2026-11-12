import 'package:flutter/material.dart';

/// Colores corporativos de Coach App - Orange Edition.
abstract final class AppColors {
  AppColors._();

  // Identidad corporativa - Naranja
  static const Color primary = Color(0xFFF56A00);           // Naranja principal
  static const Color primaryDark = Color(0xFFC94F00);       // Naranja oscuro
  static const Color primaryLight = Color(0xFFFF963F);      // Naranja secundario
  static const Color accent = Color(0xFFFFE0CC);            // Naranja suave

  // Superficies
  static const Color background = Color(0xFFFFF7F2);        // Crema cálida
  static const Color surface = Color(0xFFFFFFFF);           // Blanco
  static const Color surfaceSecondary = Color(0xFFFFF0E6);  // Crema secundaria

  // Textos
  static const Color textPrimary = Color(0xFF17212B);       // Azul grafito
  static const Color textSecondary = Color(0xFF6B7280);     // Gris
  static const Color textDisabled = Color(0xFF9CA3AF);      // Gris claro

  // Bordes
  static const Color border = Color(0xFFE5E7EB);            // Gris borde
  static const Color divider = Color(0xFFE5E7EB);           // Gris divider

  // Estados semánticos
  static const Color success = Color(0xFF15803D);           // Verde
  static const Color warning = Color(0xFFD97706);           // Ámbar
  static const Color error = Color(0xFFDC2626);             // Rojo
  static const Color info = Color(0xFF0284C7);              // Azul

  // Misc
  static const Color transparent = Colors.transparent;
}