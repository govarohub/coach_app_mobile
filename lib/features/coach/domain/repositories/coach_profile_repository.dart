import '../entities/coach_public_identity.dart';
import '../entities/coach_profile.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: coach_profile_repository.dart
///
/// Contrato de acceso a los datos del perfil profesional del Coach.
///
/// CK-012.2
/// Consulta de Coaches desde Firestore.
/// ---------------------------------------------------------------------------

abstract interface class CoachProfileRepository {
  /// Obtiene el perfil profesional de un Coach específico.
  Future<CoachProfile> getProfile(String coachId);

  /// Obtiene todos los perfiles profesionales registrados.
  ///
  /// CK-012.2:
  /// La consulta recupera los Coaches existentes sin aplicar
  /// filtros adicionales.
  Future<List<CoachProfile>> getCoaches();


  /// -------------------------------------------------------------------------
  /// CK-013.3
  ///
  /// Obtiene la identidad pública del Coach.
  /// -------------------------------------------------------------------------
  Future<CoachPublicIdentity> getPublicIdentity(String coachId);

  /// Actualiza la información profesional del Coach.
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