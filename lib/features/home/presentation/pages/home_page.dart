import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_environment_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Página principal.
///
/// En CK-004.3 se convierte en ConsumerWidget para establecer el patrón
/// definitivo de integración entre Riverpod y las pantallas.
///
/// La lógica funcional del Home se implementará posteriormente en CK-008.
/// ---------------------------------------------------------------------------
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtiene el entorno actual desde Riverpod.
    //
    // La pantalla no conoce cómo se obtiene esta información.
    // Solo consume el provider.
    final environment = ref.watch(appEnvironmentProvider);

    return Scaffold(
      body: Center(
        child: Text(
          'Home Screen\n'
              'Environment: $environment',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}