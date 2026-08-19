import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../models/user_model.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// AuthRepositoryImpl
///
/// Implementación concreta del contrato de autenticación.
///
/// Esta clase conecta Domain con Firebase mediante el DataSource.
/// ---------------------------------------------------------------------------

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required FirebaseAuthDataSource dataSource})
    : _dataSource = dataSource;

  final FirebaseAuthDataSource _dataSource;

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

  @override
  AppUser? get currentUser => _mapUser(_dataSource.currentUser);

  @override
  Stream<AppUser?> get authStateChanges {
    return _dataSource.authStateChanges.map(_mapUser);
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

    return _mapUser(credential.user)!;
  }

  @override
  Future<AppUser?> reloadCurrentUser() async {
    final user = await _dataSource.reloadCurrentUser();

    return _mapUser(user);
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
