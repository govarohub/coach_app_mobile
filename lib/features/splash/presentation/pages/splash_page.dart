import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

/// ---------------------------------------------------------------------------
/// SplashPage
///
/// Pantalla inicial de Coach.
///
/// Responsabilidades de CK-006:
/// - Mostrar la identidad inicial de la aplicación.
/// - Mantener una presentación breve.
/// - Continuar automáticamente hacia Onboarding.
///
/// No contiene:
/// - Validación de autenticación.
/// - Consulta de Firebase.
/// - Carga de perfil.
/// - Redirección según sesión.
///
/// La validación de autenticación será incorporada en CK-007.
/// ---------------------------------------------------------------------------
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

/// Estado de la pantalla Splash.
class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    // Iniciamos la transición después de mostrar brevemente el Splash.
    _startSplash();
  }

  /// Controla la duración de la pantalla Splash.
  Future<void> _startSplash() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    // Evitamos navegar si el widget ya fue desmontado.
    if (!mounted) {
      return;
    }

    // CK-006 lleva al usuario al onboarding.
    //
    // CK-007 posteriormente podrá modificar este flujo cuando exista
    // autenticación y persistencia de sesión.
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Identidad provisional de la aplicación.
            //
            // El branding definitivo puede sustituirse posteriormente
            // sin modificar la lógica de navegación.
            Icon(
              Icons.psychology_outlined,
              size: 96,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 24),

            Text('Coach', style: Theme.of(context).textTheme.headlineLarge),

            const SizedBox(height: 8),

            Text(
              'Tu camino hacia tus objetivos',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Indicador visual mientras se prepara la transición.
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
