import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options.dart';
import 'app.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Bootstrap de la aplicación.
///
/// Responsabilidades:
/// - Inicializar Flutter.
/// - Inicializar Firebase.
/// - Crear el ámbito global de Riverpod.
/// - Ejecutar CoachApp.
///
/// No contiene lógica de negocio.
/// ---------------------------------------------------------------------------
Future<void> bootstrap() async {
  // Garantiza la inicialización de Flutter antes
  // de ejecutar cualquier configuración global.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase utilizando la configuración generada
  // por FlutterFire para la plataforma actual.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ProviderScope crea el contenedor global de Riverpod.
  //
  // Todos los providers de la aplicación estarán disponibles
  // debajo de este punto del árbol de widgets.
  runApp(
    const ProviderScope(
      child: CoachApp(),
    ),
  );
}