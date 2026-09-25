import '../../domain/entities/favorite_coach.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../../coach/data/datasources/firebase_coach_datasource.dart';
import '../../../coach/data/models/coach_profile_model.dart';
import '../../../coach/domain/entities/coach_public_identity.dart';
import '../datasources/firebase_favorites_datasource.dart';
import '../models/favorite_coach_model.dart';

/// Implementación concreta del Repository de Favoritos.
///
/// CK-014.3
///
/// Coordina:
/// - DataSource de favoritos.
/// - DataSource existente del módulo Coach.
///
/// Favoritos almacena únicamente la relación cliente -> Coach.
/// Los datos del Coach se obtienen de sus fuentes existentes.
class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl({
    required this._favoritesDataSource,
    required this._coachDataSource,
  });

  /// Acceso a users/{uid}/favorites.
  final FirebaseFavoritesDataSource _favoritesDataSource;

  /// DataSource existente del módulo Coach.
  final FirebaseCoachDataSource _coachDataSource;

  /// Obtiene los favoritos y resuelve la información actual
  /// de cada Coach.
  @override
  Future<List<FavoriteCoach>> getFavorites(String uid) async {
    _validateUid(uid);

    final snapshot = await _favoritesDataSource.getFavoriteDocuments(
      uid: uid,
    );

    final models = snapshot.docs
        .map(FavoriteCoachModel.fromFirestore)
        .toList();

    // Las consultas de los Coaches se ejecutan en paralelo.
    final favorites = await Future.wait(
      models.map(_buildFavoriteCoach),
    );

    // Los favoritos más recientes aparecen primero.
    favorites.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) {
        return 0;
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return bDate.compareTo(aDate);
    });

    return favorites;
  }

  /// Comprueba si existe el favorito directamente en Firestore.
  @override
  Future<bool> isFavorite({
    required String uid,
    required String coachId,
  }) async {
    _validateUid(uid);
    _validateCoachId(coachId);

    final document = await _favoritesDataSource.getFavoriteDocument(
      uid: uid,
      coachId: coachId,
    );

    return document.exists;
  }

  /// Agrega un Coach a favoritos.
  @override
  Future<void> addFavorite({
    required String uid,
    required String coachId,
  }) {
    _validateUid(uid);
    _validateCoachId(coachId);

    return _favoritesDataSource.addFavorite(
      uid: uid,
      coachId: coachId,
    );
  }

  /// Elimina un Coach de favoritos.
  @override
  Future<void> removeFavorite({
    required String uid,
    required String coachId,
  }) {
    _validateUid(uid);
    _validateCoachId(coachId);

    return _favoritesDataSource.removeFavorite(
      uid: uid,
      coachId: coachId,
    );
  }

  /// Construye la entidad de dominio FavoriteCoach.
  Future<FavoriteCoach> _buildFavoriteCoach(
      FavoriteCoachModel model,
      ) async {
    // Obtiene el perfil profesional desde el DataSource
    // existente del módulo Coach.
    final profileDocument = await _coachDataSource.getCoachDocument(
      model.coachId,
    );

    if (!profileDocument.exists) {
      throw StateError(
        'No existe el perfil profesional del Coach '
            '${model.coachId}.',
      );
    }

    final profile = CoachProfileModel.fromFirestore(
      profileDocument,
    );

    // Obtiene la identidad pública desde users/{coachId}.
    final userDocument = await _coachDataSource.getCoachUserDocument(
      model.coachId,
    );

    if (!userDocument.exists) {
      throw StateError(
        'No existe la identidad pública del Coach '
            '${model.coachId}.',
      );
    }

    final data = userDocument.data();

    if (data == null) {
      throw StateError(
        'El documento del usuario del Coach '
            '${model.coachId} no contiene información.',
      );
    }

    final name = data['name'] as String? ?? '';

    if (name.trim().isEmpty) {
      throw StateError(
        'El Coach ${model.coachId} no tiene un nombre registrado.',
      );
    }

    // Reutilizamos la entidad existente de CK-013.
    final identity = CoachPublicIdentity(
      name: name.trim(),
      photoUrl: data['photoUrl'] as String?,
    );

    return FavoriteCoach(
      coachId: model.coachId,
      profile: profile,
      identity: identity,
      createdAt: model.createdAt,
    );
  }

  /// Valida el UID del usuario.
  void _validateUid(String uid) {
    if (uid.trim().isEmpty) {
      throw ArgumentError(
        'El UID del usuario es obligatorio.',
      );
    }
  }

  /// Valida el ID del Coach.
  void _validateCoachId(String coachId) {
    if (coachId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del Coach es obligatorio.',
      );
    }
  }
}