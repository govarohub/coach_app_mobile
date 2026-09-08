import '../entities/coach_profile.dart';

/// Contrato para consultar y actualizar el perfil profesional del Coach.
abstract interface class CoachProfileRepository {
  /// Obtiene el perfil profesional asociado al Coach autenticado.
  Future<CoachProfile> getProfile(String coachId);

  /// Actualiza la información profesional editable del Coach.
  ///
  /// Los campos rating y verified no forman parte de la actualización
  /// porque no son datos administrados directamente por el Coach.
  Future<CoachProfile> updateProfile({
    required String coachId,
    required List<String> specialties,
    required int experienceYears,
    required double hourlyRate,
    required String? bio,
    required CoachLocation? location,
    required bool available,
  });
}