import '../entities/app_user.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// AuthRepository
///
/// Contrato de autenticación.
///
/// El dominio conoce las operaciones disponibles, pero no conoce Firebase.
/// ---------------------------------------------------------------------------

abstract interface class AuthRepository {
  /// Usuario actualmente autenticado.
  AppUser? get currentUser;

  /// Stream que informa cambios en el estado de autenticación.
  Stream<AppUser?> get authStateChanges;

  /// Inicia sesión con correo y contraseña.
  Future<AppUser> signIn({required String email, required String password});

  /// Registra un nuevo usuario.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });

  /// Actualiza el estado de autenticación desde Firebase.
  Future<AppUser?> reloadCurrentUser();

  /// Envía correo para restablecer contraseña.
  Future<void> sendPasswordResetEmail({required String email});

  /// Envía nuevamente el correo de verificación.
  Future<void> sendEmailVerification();

  /// Actualiza los datos básicos del perfil.
  Future<AppUser> completeProfile({
    required String firstName,
    required String lastName,
  });

  /// Cierra la sesión.
  Future<void> signOut();
}
