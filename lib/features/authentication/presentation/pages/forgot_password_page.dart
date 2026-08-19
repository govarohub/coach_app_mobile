import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// ForgotPasswordPage
///
/// Envía el correo de recuperación mediante Firebase Authentication.
/// ---------------------------------------------------------------------------

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo válido.')),
      );
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(email: email);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si el correo existe, recibirás instrucciones para '
            'restablecer tu contraseña.',
          ),
        ),
      );
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible procesar la solicitud: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sendReset,
              child: const Text('Enviar instrucciones'),
            ),
          ],
        ),
      ),
    );
  }
}
