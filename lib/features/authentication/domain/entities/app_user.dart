/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// AppUser
///
/// Entidad de dominio del usuario autenticado.
///
/// Esta clase NO depende de Firebase ni de Flutter.
/// ---------------------------------------------------------------------------

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.role = 'client',
    this.profileCompleted = false,
    this.emailVerified = false,
  });

  final String id;
  final String email;

  final String? displayName;
  final String? firstName;
  final String? lastName;

  /// Rol oficial inicial para un usuario registrado desde la aplicación.
  final String role;

  /// Indica si el usuario terminó el perfil inicial.
  final bool profileCompleted;

  /// Estado de verificación del correo.
  final bool emailVerified;
}
