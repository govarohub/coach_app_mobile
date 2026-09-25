import '../../../coach/domain/entities/coach_profile.dart';
import '../../../coach/domain/entities/coach_public_identity.dart';

/// Representa un Coach guardado como favorito por un cliente.
///
/// CK-014.1 — Entidad de dominio.
///
/// La entidad no conoce Firestore. El perfil profesional y la identidad
/// pública se reutilizan desde el módulo `coach` para evitar duplicación.
class FavoriteCoach {
  const FavoriteCoach({
    required this.coachId,
    required this.profile,
    required this.identity,
    this.createdAt,
  });

  /// Identificador único del Coach.
  final String coachId;

  /// Perfil profesional actual del Coach.
  final CoachProfile profile;

  /// Identidad pública actual del Coach.
  final CoachPublicIdentity identity;

  /// Fecha en la que se creó la relación de favorito, si está disponible.
  final DateTime? createdAt;
}