import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/providers/auth_state_provider.dart';
import '../../coach/data/datasources/firebase_coach_datasource.dart';
import '../data/datasources/firebase_favorites_datasource.dart';
import '../data/repositories/favorites_repository_impl.dart';
import '../domain/entities/favorite_coach.dart';
import '../domain/repositories/favorites_repository.dart';

/// -------------------------------------------------------------------------
/// CK-014.4
///
/// DataSource de Favoritos.
/// -------------------------------------------------------------------------
final firebaseFavoritesDataSourceProvider =
Provider<FirebaseFavoritesDataSource>((ref) {
  return FirebaseFavoritesDataSource();
});

/// -------------------------------------------------------------------------
/// CK-014.4
///
/// DataSource del módulo Coach utilizado por Favoritos para recuperar
/// la información pública del Coach.
/// -------------------------------------------------------------------------
final firebaseCoachDataSourceProviderForFavorites =
Provider<FirebaseCoachDataSource>((ref) {
  return FirebaseCoachDataSource();
});

/// -------------------------------------------------------------------------
/// CK-014.4
///
/// Repository de Favoritos.
///
/// El Provider conecta los DataSources con la implementación del Repository.
/// La capa de presentación no accede directamente a Firebase.
/// -------------------------------------------------------------------------
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final favoritesDataSource = ref.watch(
    firebaseFavoritesDataSourceProvider,
  );

  final coachDataSource = ref.watch(
    firebaseCoachDataSourceProviderForFavorites,
  );

  return FavoritesRepositoryImpl(
    favoritesDataSource: favoritesDataSource,
    coachDataSource: coachDataSource,
  );
});

/// -------------------------------------------------------------------------
/// CK-014.4
///
/// Obtiene la lista de Coaches favoritos del usuario autenticado.
/// -------------------------------------------------------------------------
final favoritesProvider = FutureProvider<List<FavoriteCoach>>((ref) async {
  final authState = await ref.watch(authStateProvider.future);

  if (authState == null) {
    throw StateError(
      'No existe una sesión de usuario activa.',
    );
  }

  return ref.watch(
    favoritesRepositoryProvider,
  ).getFavorites(authState.id);
});

/// -------------------------------------------------------------------------
/// CK-014.4
///
/// Obtiene el estado de favorito de un Coach específico.
///
/// true  = el Coach está en favoritos.
/// false = el Coach no está en favoritos.
/// -------------------------------------------------------------------------
final favoriteStatusProvider =
FutureProvider.family<bool, String>((ref, coachId) async {
  final authState = await ref.watch(authStateProvider.future);

  if (authState == null) {
    return false;
  }

  return ref.watch(
    favoritesRepositoryProvider,
  ).isFavorite(
    uid: authState.id,
    coachId: coachId,
  );
});

/// -------------------------------------------------------------------------
/// CK-014.4
///
/// Controller responsable de agregar y eliminar favoritos.
///
/// La pantalla únicamente utiliza este Controller y no accede directamente
/// a Firebase.
/// -------------------------------------------------------------------------
class FavoritesController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Agrega un Coach a favoritos.
  Future<void> addFavorite({
    required String coachId,
  }) async {
    state = const AsyncLoading();

    try {
      final authState = await ref.read(
        authStateProvider.future,
      );

      if (authState == null) {
        throw StateError(
          'No existe una sesión de usuario activa.',
        );
      }

      await ref.read(
        favoritesRepositoryProvider,
      ).addFavorite(
        uid: authState.id,
        coachId: coachId,
      );

      // Actualiza la lista de favoritos.
      ref.invalidate(favoritesProvider);

      // Actualiza el estado del botón del Coach.
      ref.invalidate(
        favoriteStatusProvider(coachId),
      );

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );

      rethrow;
    }
  }

  /// Elimina un Coach de favoritos.
  Future<void> removeFavorite({
    required String coachId,
  }) async {
    state = const AsyncLoading();

    try {
      final authState = await ref.read(
        authStateProvider.future,
      );

      if (authState == null) {
        throw StateError(
          'No existe una sesión de usuario activa.',
        );
      }

      await ref.read(
        favoritesRepositoryProvider,
      ).removeFavorite(
        uid: authState.id,
        coachId: coachId,
      );

      // Actualiza la lista de favoritos.
      ref.invalidate(favoritesProvider);

      // Actualiza el estado del botón del Coach.
      ref.invalidate(
        favoriteStatusProvider(coachId),
      );

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );

      rethrow;
    }
  }

  /// Alterna el estado de favorito de un Coach.
  Future<void> toggleFavorite({
    required String coachId,
  }) async {
    final isFavorite = await ref.read(
      favoriteStatusProvider(coachId).future,
    );

    if (isFavorite) {
      await removeFavorite(
        coachId: coachId,
      );
    } else {
      await addFavorite(
        coachId: coachId,
      );
    }
  }
}

/// -------------------------------------------------------------------------
/// CK-014.4
///
/// Provider del Controller de Favoritos.
/// -------------------------------------------------------------------------
final favoritesControllerProvider =
AsyncNotifierProvider<FavoritesController, void>(
  FavoritesController.new,
);