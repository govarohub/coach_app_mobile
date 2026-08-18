import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ---------------------------------------------------------------------------
/// Firebase Cloud Messaging Providers
///
/// Responsabilidades:
/// - Exponer la instancia de Firebase Messaging mediante Riverpod.
/// - Mantener FCM desacoplado de la interfaz.
/// - Proporcionar un único punto de acceso a FirebaseMessaging.
///
/// Este archivo pertenece a la infraestructura de Firebase.
///
/// No contiene:
/// - Solicitud de permisos al usuario.
/// - Obtención del token FCM.
/// - Manejo de notificaciones.
/// - Navegación al recibir una notificación.
/// - Persistencia del token.
/// - Notificaciones locales.
/// - Lógica de negocio.
///
/// Esas responsabilidades se implementarán en los CK correspondientes.
/// ---------------------------------------------------------------------------

/// Provider de la instancia principal de Firebase Cloud Messaging.
///
/// Firebase Core se inicializa previamente en bootstrap.dart.
/// Por ello aquí únicamente obtenemos la instancia de Messaging.
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});