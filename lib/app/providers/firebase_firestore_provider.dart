import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ---------------------------------------------------------------------------
/// Firebase Cloud Firestore Providers
///
/// Responsabilidades:
/// - Exponer la instancia de Cloud Firestore mediante Riverpod.
/// - Mantener el acceso a Firestore desacoplado de la interfaz.
/// - Proporcionar un punto único de acceso a la instancia de Firestore.
///
/// Este archivo pertenece a la infraestructura de Firebase.
///
/// No contiene:
/// - Colecciones específicas del negocio.
/// - Modelos.
/// - Consultas de usuarios.
/// - CRUD.
/// - Reglas de seguridad.
/// - Lógica de presentación.
///
/// Esas responsabilidades se implementarán en las etapas correspondientes.
/// ---------------------------------------------------------------------------

/// Provider de la instancia principal de Cloud Firestore.
///
/// FirebaseFirestore.instance utiliza la aplicación Firebase inicializada
/// previamente en bootstrap.dart.
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});