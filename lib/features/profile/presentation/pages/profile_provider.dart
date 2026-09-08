import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firebase_profile_datasource.dart';
import '../../data/repositories/client_profile_repository_impl.dart';
import '../../data/services/profile_image_storage_service.dart';
import '../../domain/entities/client_profile.dart';
import '../../domain/repositories/client_profile_repository.dart';
import '../../../authentication/presentation/providers/auth_state_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: profile_provider.dart
///
/// Providers de la feature Profile.
///
/// CK-009.7.6:
/// - Centraliza las operaciones del avatar.
/// - Controla el estado de procesamiento de la fotografía.
/// - Mantiene visible el perfil durante las operaciones del avatar.
/// - Centraliza el manejo de errores mediante AsyncValue.
/// ---------------------------------------------------------------------------

/// DataSource de Firebase para la feature Profile.
final firebaseProfileDataSourceProvider = Provider<FirebaseProfileDataSource>((
  ref,
) {
  return FirebaseProfileDataSource();
});

/// Repository de Profile.
///
/// La UI no accede directamente al repository.
final clientProfileRepositoryProvider = Provider<ClientProfileRepository>((
  ref,
) {
  return ClientProfileRepositoryImpl(
    dataSource: ref.watch(firebaseProfileDataSourceProvider),
  );
});

/// Servicio responsable de seleccionar, subir y eliminar fotografías.
final profileImageStorageServiceProvider = Provider<ProfileImageStorageService>(
  (ref) {
    return ProfileImageStorageService();
  },
);

/// Indica si actualmente se está procesando una fotografía.
///
/// Se mantiene separado de profileProvider para evitar que toda la pantalla
/// vuelva al estado de loading durante una operación del avatar.
final profileImageProcessingProvider = StateProvider<bool>((ref) {
  return false;
});

/// Estado del perfil del cliente autenticado.
final profileProvider = AsyncNotifierProvider<ProfileNotifier, ClientProfile?>(
  ProfileNotifier.new,
);

/// Notifier responsable de cargar y actualizar el perfil.
class ProfileNotifier extends AsyncNotifier<ClientProfile?> {
  @override
  Future<ClientProfile?> build() async {
    final authState = ref.watch(authStateProvider);

    // El provider de autenticación utiliza nuestra entidad AppUser.
    final user = authState.asData?.value;

    if (user == null) {
      return null;
    }

    return ref.read(clientProfileRepositoryProvider).getProfile(user.id);
  }

  /// Actualiza nombre y teléfono del cliente.
  Future<void> updateProfile({
    required String name,
    required String? phone,
  }) async {
    final authState = ref.read(authStateProvider);
    final currentUser = authState.asData?.value;

    if (currentUser == null) {
      state = AsyncError(
        StateError('No existe un usuario autenticado.'),
        StackTrace.current,
      );
      return;
    }

    // Normalizamos los datos antes de enviarlos al Repository.
    final trimmedName = name.trim();
    final trimmedPhone = phone?.trim();

    // Validación defensiva en la capa de estado.
    // La UI también valida estos datos, pero el Notifier
    // mantiene la regla para evitar persistir un nombre vacío.
    if (trimmedName.isEmpty) {
      state = AsyncError(
        ArgumentError('El nombre no puede estar vacío.'),
        StackTrace.current,
      );
      return;
    }

    // Conservamos el perfil actual mientras la actualización
    // se encuentra en proceso.
    final previousState = state;

    // Indicamos explícitamente que la actualización está en curso.
    state = const AsyncLoading<ClientProfile?>();

    try {
      // Persistimos los cambios mediante el Repository.
      final updatedProfile = await ref
          .read(clientProfileRepositoryProvider)
          .updateProfile(
        uid: currentUser.id,
        name: trimmedName,
        phone: trimmedPhone?.isEmpty == true ? null : trimmedPhone,
      );

      // Firestore devolvió el perfil actualizado.
      // Lo reflejamos inmediatamente en el estado de Riverpod.
      state = AsyncData(updatedProfile);
    } catch (error, stackTrace) {
      // Conservamos el error para que la UI pueda informar
      // que la actualización no pudo completarse.
      state = AsyncError(error, stackTrace);

      // Si ya existía un perfil válido, recuperamos nuevamente
      // los datos desde Firestore para evitar inconsistencias
      // entre la aplicación y la base de datos.
      if (previousState.value != null) {
        await _restoreProfileAfterError();
      }
    }
  }


  /// Selecciona y sube una nueva fotografía de perfil.
  Future<void> pickAndUploadProfileImage() async {
    final authState = ref.read(authStateProvider);
    final currentUser = authState.asData?.value;

    if (currentUser == null) {
      state = AsyncError(
        StateError('No existe un usuario autenticado.'),
        StackTrace.current,
      );
      return;
    }

    // Evita ejecutar dos operaciones de fotografía simultáneamente.
    if (ref.read(profileImageProcessingProvider)) {
      return;
    }

    ref.read(profileImageProcessingProvider.notifier).state = true;

    try {
      final storageService = ref.read(profileImageStorageServiceProvider);

      // El servicio gestiona el selector y la carga en Storage.
      final photoUrl = await storageService.pickAndUploadProfileImage(
        uid: currentUser.id,
      );

      // Cancelar la selección no modifica el estado actual.
      if (photoUrl == null) {
        return;
      }

      // Persistimos la URL en Firestore mediante el Repository.
      final updatedProfile = await ref
          .read(clientProfileRepositoryProvider)
          .updateProfilePhoto(uid: currentUser.id, photoUrl: photoUrl);

      // Actualizamos inmediatamente el perfil en memoria.
      state = AsyncData(updatedProfile);
    } catch (error, stackTrace) {
      // Conservamos el perfil anterior y reportamos el error mediante
      // AsyncError para que la UI pueda mostrar un mensaje.
      final currentProfile = state.value;

      state = AsyncValue.error(error, stackTrace);

      // Si existía un perfil válido, se recupera posteriormente mediante
      // reloadProfile sin dejar datos inconsistentes en Firestore.
      if (currentProfile != null) {
        await _restoreProfileAfterError();
      }
    } finally {
      ref.read(profileImageProcessingProvider.notifier).state = false;
    }
  }

  /// Elimina la fotografía actual del usuario.
  Future<void> removeProfileImage() async {
    final authState = ref.read(authStateProvider);
    final currentUser = authState.asData?.value;

    if (currentUser == null) {
      state = AsyncError(
        StateError('No existe un usuario autenticado.'),
        StackTrace.current,
      );
      return;
    }

    if (ref.read(profileImageProcessingProvider)) {
      return;
    }

    ref.read(profileImageProcessingProvider.notifier).state = true;

    try {
      final storageService = ref.read(profileImageStorageServiceProvider);

      // Primero eliminamos el archivo físico de Firebase Storage.
      await storageService.removeProfileImage(uid: currentUser.id);

      // Después eliminamos la URL persistida en Firestore.
      final updatedProfile = await ref
          .read(clientProfileRepositoryProvider)
          .updateProfilePhoto(uid: currentUser.id, photoUrl: null);

      // Reflejamos inmediatamente el cambio en la UI.
      state = AsyncData(updatedProfile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);

      await _restoreProfileAfterError();
    } finally {
      ref.read(profileImageProcessingProvider.notifier).state = false;
    }
  }

  /// Recupera el perfil desde Firestore después de una operación fallida.
  Future<void> _restoreProfileAfterError() async {
    try {
      final authState = ref.read(authStateProvider);
      final currentUser = authState.asData?.value;

      if (currentUser == null) {
        return;
      }

      final profile = await ref
          .read(clientProfileRepositoryProvider)
          .getProfile(currentUser.id);

      state = AsyncData(profile);
    } catch (_) {
      // No reemplazamos el error original por un error secundario.
    }
  }

  /// Fuerza nuevamente la lectura del perfil desde Firestore.
  Future<void> reloadProfile() async {
    ref.invalidateSelf();
    await future;
  }
}
