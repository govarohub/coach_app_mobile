import 'package:cloud_firestore/cloud_firestore.dart';

/// DataSource de Firebase para la gestión de favoritos.
///
/// CK-014.2
///
/// Responsabilidad:
/// - Acceder exclusivamente a Firestore.
/// - Crear, consultar y eliminar relaciones de favoritos.
///
/// Persistencia:
/// users/{uid}/favorites/{coachId}
///
/// Este archivo no contiene:
/// - lógica de presentación;
/// - entidades de dominio;
/// - navegación;
/// - lógica de negocio del Coach.
class FirebaseFavoritesDataSource {
  FirebaseFavoritesDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Instancia de Firestore utilizada por el DataSource.
  final FirebaseFirestore _firestore;

  /// Obtiene todos los favoritos de un usuario.
  Future<QuerySnapshot<Map<String, dynamic>>> getFavoriteDocuments({
    required String uid,
  }) {
    _validateUid(uid);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .get();
  }

  /// Obtiene un favorito específico.
  ///
  /// Permite comprobar si un Coach está marcado como favorito.
  Future<DocumentSnapshot<Map<String, dynamic>>> getFavoriteDocument({
    required String uid,
    required String coachId,
  }) {
    _validateUid(uid);
    _validateCoachId(coachId);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(coachId)
        .get();
  }

  /// Agrega un Coach a los favoritos.
  ///
  /// El coachId se utiliza como ID del documento para evitar
  /// registros duplicados del mismo Coach.
  Future<void> addFavorite({
    required String uid,
    required String coachId,
  }) {
    _validateUid(uid);
    _validateCoachId(coachId);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(coachId)
        .set({
      // Identificador del Coach favorito.
      'coachId': coachId,

      // Firebase genera la fecha en el servidor.
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina un Coach de los favoritos.
  Future<void> removeFavorite({
    required String uid,
    required String coachId,
  }) {
    _validateUid(uid);
    _validateCoachId(coachId);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(coachId)
        .delete();
  }

  /// Valida el UID antes de construir la ruta de Firestore.
  void _validateUid(String uid) {
    if (uid.trim().isEmpty) {
      throw ArgumentError(
        'El UID del usuario es obligatorio.',
      );
    }
  }

  /// Valida el identificador del Coach.
  void _validateCoachId(String coachId) {
    if (coachId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del Coach es obligatorio.',
      );
    }
  }
}