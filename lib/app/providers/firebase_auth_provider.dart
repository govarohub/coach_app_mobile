import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ---------------------------------------------------------------------------
/// Firebase Authentication Providers
///
/// Responsabilidades:
/// - Exponer la instancia de FirebaseAuth mediante Riverpod.
/// - Exponer los cambios del estado de autenticación.
/// - Mantener Firebase Authentication desacoplado de la interfaz.
///
/// Este archivo pertenece a la infraestructura de Firebase.
///
/// No contiene:
/// - Pantallas de Login.
/// - Registro de usuarios.
/// - Recuperación de contraseña.
/// - Navegación.
/// - Gestión del perfil.
///
/// Esas responsabilidades se implementarán posteriormente en CK-007.
/// ---------------------------------------------------------------------------

/// Proporciona la instancia principal de Firebase Authentication.
///
/// FirebaseAuth.instance utiliza la aplicación Firebase que fue inicializada
/// previamente en bootstrap.dart.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Expone los cambios del estado de autenticación.
///
/// Firebase emite un nuevo valor cuando:
/// - Se inicia una sesión.
/// - Se cierra una sesión.
/// - Se restaura una sesión existente.
///
/// El valor será:
/// - User cuando existe una sesión autenticada.
/// - null cuando no existe una sesión.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);

  return firebaseAuth.authStateChanges();
});