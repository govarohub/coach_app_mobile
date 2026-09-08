import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../models/user_model.dart';

/// ---------------------------------------------------------------------------
/// AuthRepositoryImpl
///
/// Implementación concreta del contrato AuthRepository.
///
/// Responsabilidades:
/// - Conectar la capa de dominio con Firebase Authentication.
/// - Transformar usuarios de Firebase a AppUser/UserModel.
/// - Obtener desde Firestore datos adicionales del usuario, como el rol.
/// - Delegar las operaciones al FirebaseAuthDataSource.
/// - Mantener Firebase desacoplado de la capa de presentación.
/// ---------------------------------------------------------------------------
class AuthRepositoryImpl implements AuthRepository {
  /// Constructor.
  AuthRepositoryImpl({required this._dataSource});

  /// Fuente de datos que se comunica directamente con Firebase.
  final FirebaseAuthDataSource _dataSource;

  /// Convierte únicamente los datos disponibles desde Firebase Authentication.
  ///
  /// Se utiliza para currentUser porque el contrato actual es síncrono.
  AppUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }

  /// Convierte el usuario autenticado incorporando los datos almacenados
  /// en Firestore, principalmente el rol.
  Future<AppUser?> _mapAuthenticatedUser(User? user) async {
    if (user == null) {
      return null;
    }

    final document = await _dataSource.getUserDocument(user.uid);
    final data = document.data();

    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      emailVerified: user.emailVerified,

      // El rol se obtiene desde Firestore.
      role: data?['role'] as String? ?? 'client',

      // Conservamos el estado del perfil si existe en Firestore.
      profileCompleted: data?['profileCompleted'] as bool? ?? false,
    );
  }

  @override
  AppUser? get currentUser => _mapUser(_dataSource.currentUser);

  @override
  Stream<AppUser?> get authStateChanges {
    return _dataSource.authStateChanges.asyncMap(_mapAuthenticatedUser);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _dataSource.signIn(
      email: email,
      password: password,
    );

    // Después del inicio de sesión recuperamos también el rol desde Firestore.
    return (await _mapAuthenticatedUser(credential.user))!;
  }

  @override
  Future<AppUser?> reloadCurrentUser() async {
    final user = await _dataSource.reloadCurrentUser();

    // Al recargar también recuperamos el rol desde Firestore.
    return _mapAuthenticatedUser(user);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final credential = await _dataSource.signUp(
      email: email,
      password: password,
    );

    final user = credential.user!;

    final displayName = '$firstName $lastName'.trim();

    await _dataSource.updateDisplayName(displayName);

    final model = UserModel(
      id: user.uid,
      email: email,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,

      // Los registros nuevos continúan siendo clientes.
      role: 'client',

      profileCompleted: false,
      emailVerified: user.emailVerified,
    );

    await _dataSource.saveUserDocument(
      uid: user.uid,
      data: model.toFirestore(),
    );

    await _dataSource.sendEmailVerification();

    return model;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _dataSource.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() {
    return _dataSource.sendEmailVerification();
  }

  @override
  Future<AppUser> completeProfile({
    required String firstName,
    required String lastName,
  }) async {
    final user = _dataSource.currentUser;

    if (user == null) {
      throw StateError('No existe un usuario autenticado.');
    }

    final displayName = '$firstName $lastName'.trim();

    await _dataSource.updateDisplayName(displayName);

    final model = UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,

      // El flujo normal de registro continúa creando clientes.
      role: 'client',

      profileCompleted: true,
      emailVerified: user.emailVerified,
    );

    await _dataSource.saveUserDocument(
      uid: user.uid,
      data: model.toFirestore(),
    );

    return model;
  }

  @override
  Future<void> signOut() {
    return _dataSource.signOut();
  }
}