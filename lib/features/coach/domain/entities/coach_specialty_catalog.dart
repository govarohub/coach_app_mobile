import 'coach_specialty.dart';

/// Catálogo centralizado de especialidades profesionales.
abstract final class CoachSpecialtyCatalog {
  CoachSpecialtyCatalog._();

  /// Lista base del catálogo.
  ///
  /// No se agregan especialidades todavía porque la especificación oficial
  /// no define los valores concretos del catálogo.
  static const List<CoachSpecialty> items = <CoachSpecialty>[];
}