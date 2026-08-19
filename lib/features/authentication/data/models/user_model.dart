import '../../domain/entities/app_user.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// UserModel
///
/// Modelo utilizado para transformar datos entre Firebase y el dominio.
/// ---------------------------------------------------------------------------

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.firstName,
    super.lastName,
    super.role,
    super.profileCompleted,
    super.emailVerified,
  });

  /// Convierte una entidad de dominio en datos para Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'profileCompleted': profileCompleted,
      'emailVerified': emailVerified,
    };
  }
}
