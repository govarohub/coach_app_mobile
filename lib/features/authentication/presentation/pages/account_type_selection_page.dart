import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// AccountTypeSelectionPage
///
/// Permite al usuario seleccionar si desea registrarse como Coach/Entrenador
/// o como Cliente.
/// ---------------------------------------------------------------------------

class AccountTypeSelectionPage extends StatelessWidget {
  const AccountTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Cuál es tu rol?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona si eres un entrenador/coach o un cliente',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () {
                  context.go(AppRoutes.registerCoach);
                },
                icon: const Icon(Icons.school),
                label: const Text('Soy Entrenador/Coach'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  context.go(AppRoutes.register);
                },
                icon: const Icon(Icons.person),
                label: const Text('Soy Cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
