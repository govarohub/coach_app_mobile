import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/registration_password_fields.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// CoachRegisterPage
///
/// Registro de un Coach/Entrenador.
///
/// Al registrarse se crea la cuenta con rol 'coach', el documento users
/// en Firestore y se envía la verificación del correo.
/// ---------------------------------------------------------------------------

class CoachRegisterPage extends ConsumerStatefulWidget {
  const CoachRegisterPage({super.key});

  @override
  ConsumerState<CoachRegisterPage> createState() => _CoachRegisterPageState();
}

class _CoachRegisterPageState extends ConsumerState<CoachRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUpCoach(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      context.go(AppRoutes.verifyEmail);
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible crear la cuenta: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrarse como Coach')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu nombre.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Apellidos'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tus apellidos.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu correo.';
                  }

                  if (!value.contains('@')) {
                    return 'Ingresa un correo válido.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              RegistrationPasswordFields(
                passwordController: _passwordController,
                confirmationController: _confirmationController,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: authState.isLoading ? null : _register,
                child: authState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Registrarme'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
