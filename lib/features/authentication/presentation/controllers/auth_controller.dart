import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../providers/auth_state_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// AuthController
///
/// Ejecuta las operaciones de autenticación solicitadas por la presentación.
///
/// La UI no conoce Firebase.
/// ---------------------------------------------------------------------------

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Inicia sesión.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);

      state = const AsyncData(null);

      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Registra un usuario cliente.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = const AsyncLoading();

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
          );

      state = const AsyncData(null);

      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Envía recuperación de contraseña.
  Future<void> resetPassword({required String email}) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email: email);

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Actualiza el estado del usuario después de verificar el correo.
  Future<AppUser?> reloadCurrentUser() {
    return ref.read(authRepositoryProvider).reloadCurrentUser();
  }

  /// Envía nuevamente el correo de verificación.
  Future<void> sendEmailVerification() async {
    await ref.read(authRepositoryProvider).sendEmailVerification();
  }

  /// Completa el perfil inicial.
  Future<AppUser> completeProfile({
    required String firstName,
    required String lastName,
  }) async {
    state = const AsyncLoading();

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .completeProfile(firstName: firstName, lastName: lastName);

      state = const AsyncData(null);

      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Cierra la sesión.
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}
