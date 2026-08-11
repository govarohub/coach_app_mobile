import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Bootstrap de la aplicación.
///
/// Responsabilidades:
/// - Inicializar Flutter.
/// - Crear el ámbito global de Riverpod.
/// - Ejecutar CoachApp.
///
/// No contiene lógica de negocio.
/// ---------------------------------------------------------------------------
Future<void> bootstrap() async {
  // Garantiza la inicialización de Flutter antes
  // de ejecutar la aplicación.
  WidgetsFlutterBinding.ensureInitialized();

  // ProviderScope proporciona el contenedor global
  // para todos los providers de Riverpod.
  runApp(
    const ProviderScope(
      child: CoachApp(),
    ),
  );
}