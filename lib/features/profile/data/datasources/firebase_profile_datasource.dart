import 'package:cloud_firestore/cloud_firestore.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: firebase_profile_datasource.dart
///
/// Único punto de acceso de esta feature hacia Cloud Firestore.
/// ---------------------------------------------------------------------------

class FirebaseProfileDataSource {
  FirebaseProfileDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Obtiene el documento users/{uid}.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  /// Actualiza únicamente los campos modificables del perfil.
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String? phone,
  }) {
    return _firestore.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Persiste la URL de la fotografía del perfil en Firestore.
  ///
  /// No modifica el resto de los datos del usuario.
  Future<void> updateUserProfilePhoto({
    required String uid,
    required String? photoUrl,
  }) {
    return _firestore.collection('users').doc(uid).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
