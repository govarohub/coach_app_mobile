import '../../domain/entities/client_profile.dart';
import '../../domain/repositories/client_profile_repository.dart';
import '../datasources/firebase_profile_datasource.dart';
import '../models/client_profile_model.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: client_profile_repository_impl.dart
///
/// Implementación concreta del contrato de perfil.
/// ---------------------------------------------------------------------------

class ClientProfileRepositoryImpl implements ClientProfileRepository {
  ClientProfileRepositoryImpl({required this._dataSource});

  final FirebaseProfileDataSource _dataSource;

  @override
  Future<ClientProfile> getProfile(String uid) async {
    final document = await _dataSource.getUserDocument(uid);

    if (!document.exists) {
      throw StateError('No existe el perfil del usuario autenticado.');
    }

    return ClientProfileModel.fromFirestore(document);
  }

  @override
  Future<ClientProfile> updateProfile({
    required String uid,
    required String name,
    required String? phone,
  }) async {
    await _dataSource.updateUserProfile(uid: uid, name: name, phone: phone);

    final document = await _dataSource.getUserDocument(uid);

    if (!document.exists) {
      throw StateError('No fue posible recuperar el perfil actualizado.');
    }

    return ClientProfileModel.fromFirestore(document);
  }

  @override
  Future<ClientProfile> updateProfilePhoto({
    required String uid,
    required String? photoUrl,
  }) async {
    // Persistimos únicamente la URL de la fotografía.
    await _dataSource.updateUserProfilePhoto(uid: uid, photoUrl: photoUrl);

    // Recuperamos el documento para sincronizar el estado local
    // con el estado real de Firestore.
    final document = await _dataSource.getUserDocument(uid);

    if (!document.exists) {
      throw StateError(
        'No fue posible recuperar el perfil después de actualizar '
        'la fotografía.',
      );
    }

    return ClientProfileModel.fromFirestore(document);
  }
}
