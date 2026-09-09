import 'coach_specialty_catalog.dart';

/// Representa el perfil profesional de un Coach.
class CoachProfile {
  const CoachProfile({
    required this.coachId,
    required this.specialties,
    required this.experienceYears,
    required this.hourlyRate,
    required this.rating,
    required this.verified,
    this.bio,
    this.location,
    required this.available,
  });

  /// Identificador del Coach.
  final String coachId;

  /// Especialidades asociadas al perfil profesional.
  /// actualmente por el modelo y la persistencia en Firestore.
  final List<String> specialties;

  /// Años de experiencia profesional.
  final int experienceYears;

  /// Tarifa por hora.
  final double hourlyRate;

  /// Calificación promedio del Coach.
  final double rating;

  /// Indica si el perfil fue verificado.
  final bool verified;

  /// Biografía profesional opcional.
  final String? bio;

  /// Ubicación profesional opcional.
  final CoachLocation? location;

  /// Indica si el Coach está disponible.
  final bool available;

  /// -------------------------------------------------------------------------
  /// CK-011.3
  ///
  /// Determina si una especialidad del perfil existe actualmente
  /// dentro del catálogo definido por la aplicación.
  ///
  /// La comparación ignora mayúsculas/minúsculas y espacios exteriores.
  ///
  /// No modifica los datos del perfil ni realiza operaciones de persistencia.
  /// -------------------------------------------------------------------------
  bool hasCatalogSpecialty(String specialtyId) {
    final normalizedId = specialtyId.trim().toLowerCase();

    if (normalizedId.isEmpty) {
      return false;
    }

    return CoachSpecialtyCatalog.items.any(
          (specialty) => specialty.id.trim().toLowerCase() == normalizedId,
    );
  }
}

/// Representa la ubicación profesional del Coach.
class CoachLocation {
  const CoachLocation({
    required this.latitude,
    required this.longitude,
  });

  /// Latitud geográfica.
  final double latitude;

  /// Longitud geográfica.
  final double longitude;
}