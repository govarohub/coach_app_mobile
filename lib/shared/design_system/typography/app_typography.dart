import 'package:flutter/material.dart';

/// Tipografía oficial de Coach App - Orange Edition (Poppins).
abstract final class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Poppins';

  // Display Large: 28px Bold (Título Principal)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  // Headline Large: 24px Bold (Título de Pantalla)
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  // Title Large: 20px SemiBold (Subtítulo)
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  // Title Medium: 18px SemiBold (Encabezado de Tarjeta)
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  // Body Large: 16px Regular (Texto Principal)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  // Body Medium: 14px Regular (Texto Secundario)
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  // Label Large: 14px SemiBold (Botones)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Label Small: 12px Medium (Etiquetas)
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}