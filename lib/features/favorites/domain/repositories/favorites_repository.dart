import '../entities/favorite_coach.dart';

/// Contrato de acceso a Favoritos.
///
/// CK-014.3
///
/// La capa de dominio define las operaciones disponibles sin conocer
/// Firestore ni detalles de implementación.
abstract interface class FavoritesRepository {
  /// Obtiene los Coaches marcados como favoritos por el usuario.
  Future<List<FavoriteCoach>> getFavorites(String uid);

  /// Indica si un Coach pertenece a los favoritos del usuario.
  Future<bool> isFavorite({
    required String uid,
    required String coachId,
  });

  /// Agrega un Coach a los favoritos.
  Future<void> addFavorite({
    required String uid,
    required String coachId,
  });

  /// Elimina un Coach de los favoritos.
  Future<void> removeFavorite({
    required String uid,
    required String coachId,
  });
}