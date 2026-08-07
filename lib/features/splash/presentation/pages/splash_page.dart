import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// SplashPage
///
/// Pantalla inicial de la aplicación.
///
/// En esta etapa únicamente representa un placeholder.
/// La lógica de carga será implementada en CK-006.
///
/// ---------------------------------------------------------------------------
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Splash Screen',
        ),
      ),
    );
  }
}