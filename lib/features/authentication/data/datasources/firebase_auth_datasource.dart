import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// FirebaseAuthDataSource
///
/// Única capa de la feature que conoce directamente Firebase Authentication
/// y Cloud Firestore.
///
/// La UI nunca accederá directamente a Firebase.
/// ---------------------------------------------------------------------------

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Usuario Firebase actualmente autenticado.
  User? get currentUser => _auth.currentUser;

  /// Cambios del estado de Firebase Authentication.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registro de usuario.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Inicio de sesión.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Envía correo de verificación.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No existe un usuario autenticado.');
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Envía recuperación de contraseña.
  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Actualiza nombre de usuario en Firebase Authentication.
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No existe un usuario autenticado.');
    }

    await user.updateDisplayName(displayName);
    await user.reload();
  }

  /// Guarda/actualiza el documento del usuario en Firestore.
  Future<void> saveUserDocument({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  /// Recarga el usuario actualmente autenticado.
  Future<User?> reloadCurrentUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    await user.reload();

    return _auth.currentUser;
  }

  /// Cierra la sesión.
  Future<void> signOut() {
    return _auth.signOut();
  }
}
