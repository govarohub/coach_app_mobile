import 'package:flutter/material.dart';

/// Sistema de sombras estandarizado de Coach App - Orange Edition.
/// Proporciona sombras consistentes para elevación visual.
abstract final class AppShadows {
  AppShadows._();

  /// Sombra pequeña para elementos sutiles (cards, chips)
  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  /// Sombra media para elementos destacados (tarjetas principales)
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 8,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Sombra grande para elementos flotantes (FABs, modales)
  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x2D000000),
      blurRadius: 12,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  /// Sombra elevada para elementos en primer plano (popups, dropdowns)
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x3D000000),
      blurRadius: 16,
      offset: Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  /// Sombra interactiva para estados hover/pressed
  static const List<BoxShadow> interactive = [
    BoxShadow(
      color: Color(0x2D000000),
      blurRadius: 10,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  /// Sin sombra (para elementos planos)
  static const List<BoxShadow> none = [];
}
