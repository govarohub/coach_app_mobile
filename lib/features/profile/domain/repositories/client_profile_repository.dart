import '../entities/client_profile.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: client_profile_repository.dart
///
/// Contrato del acceso al perfil del cliente.
/// ---------------------------------------------------------------------------

abstract interface class ClientProfileRepository {
  /// Obtiene el perfil del usuario autenticado.
  Future<ClientProfile> getProfile(String uid);

  /// Actualiza los datos editables del perfil.
  Future<ClientProfile> updateProfile({
    required String uid,
    required String name,
    required String? phone,
  });

  /// Actualiza únicamente la fotografía del perfil.
  ///
  /// La URL corresponde al archivo almacenado en Firebase Storage.
  Future<ClientProfile> updateProfilePhoto({
    required String uid,
    required String? photoUrl,
  });
}
