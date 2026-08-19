import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../app/router/app_routes.dart';
import '../controllers/auth_controller.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// VerifyEmailPage
///
/// Pantalla intermedia obligatoria después del registro.
/// ---------------------------------------------------------------------------

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  bool _checking = false;

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
    });

    try {
      await FirebaseAuth.instance.currentUser?.reload();

      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) {
        return;
      }

      if (user?.emailVerified == true) {
        context.go(AppRoutes.profileSetup);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu correo todavía no ha sido verificado.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    await ref.read(authControllerProvider.notifier).sendEmailVerification();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Correo de verificación enviado.')),
    );
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();

    if (!mounted) {
      return;
    }

    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar correo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Revisa tu correo electrónico y confirma tu cuenta.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _checking ? null : _checkVerification,
              child: _checking
                  ? const CircularProgressIndicator()
                  : const Text('Ya verifiqué mi correo'),
            ),
            TextButton(
              onPressed: _resend,
              child: const Text('Reenviar correo'),
            ),
            TextButton(onPressed: _signOut, child: const Text('Cerrar sesión')),
          ],
        ),
      ),
    );
  }
}
