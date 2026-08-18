import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ---------------------------------------------------------------------------
/// Firebase Cloud Storage Providers
///
/// Responsabilidades:
/// - Exponer la instancia de Firebase Storage mediante Riverpod.
/// - Mantener Storage desacoplado de la interfaz y de la lógica de negocio.
///
/// Este archivo pertenece a la infraestructura de Firebase.
///
/// No contiene:
/// - Subida de fotografías.
/// - Descarga de archivos.
/// - Eliminación de archivos.
/// - Rutas de archivos de usuarios.
/// - Gestión de perfiles.
/// - Lógica de negocio.
///
/// Esas responsabilidades se implementarán en los CK correspondientes.
/// ---------------------------------------------------------------------------

/// Provider de la instancia principal de Firebase Storage.
///
/// Firebase Core se inicializa previamente en bootstrap.dart.
/// Por ello aquí únicamente obtenemos la instancia de Storage.
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});