import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// HomePage
///
/// Pantalla principal.
///
/// La funcionalidad será desarrollada en CK-008.
///
/// ---------------------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Home Screen',
        ),
      ),
    );
  }
}