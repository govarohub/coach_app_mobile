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

  /// UID del Coach.
  final String coachId;

  /// Especialidades profesionales del Coach.
  final List<String> specialties;

  /// Años de experiencia profesional.
  final int experienceYears;

  /// Tarifa por hora.
  final double hourlyRate;

  /// Calificación promedio.
  final double rating;

  /// Indica si el Coach está verificado.
  final bool verified;

  /// Biografía profesional.
  final String? bio;

  /// Ubicación profesional.
  final CoachLocation? location;

  /// Indica si el Coach está disponible.
  final bool available;
}

/// ---------------------------------------------------------------------------
/// Ubicación profesional.
///
/// Se mantiene independiente de Firebase.
/// ---------------------------------------------------------------------------

class CoachLocation {
  const CoachLocation({
    required this.latitude,
    required this.longitude,
  });

  /// Latitud.
  final double latitude;

  /// Longitud.
  final double longitude;
}