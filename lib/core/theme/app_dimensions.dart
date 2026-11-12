/// Dimensiones estandarizadas de Coach App - Orange Edition.
/// Centraliza todas las medidas de la aplicación.
abstract final class AppDimensions {
  AppDimensions._();

  // Espaciado (padding, margin)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double giant = 64;

  // Radios de esquinas
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusCard = 16;
  static const double radiusLarge = 24;

  // Alturas de controles
  static const double buttonHeight = 48;
  static const double inputHeight = 48;
  static const double minTouchTarget = 48;

  // Iconografía
  static const double iconSize = 24;
  static const double iconSizeLarge = 32;
  static const double iconSizeSmall = 16;

  // Avatares
  static const double avatarSmall = 40;
  static const double avatarMedium = 56;
  static const double avatarLarge = 96;

  // Contenido
  static const double maxContentWidth = 960;
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 840;
  static const double desktopBreakpoint = 1200;

  // Elevación (sombras)
  static const double elevationNone = 0;
  static const double elevationSmall = 1;
  static const double elevationMedium = 4;
  static const double elevationLarge = 8;
  static const double elevationElevated = 12;
}
