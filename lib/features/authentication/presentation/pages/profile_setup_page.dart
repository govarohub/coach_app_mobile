import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../controllers/auth_controller.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// ProfileSetupPage
///
/// Captura los datos mínimos del perfil inicial del cliente.
/// ---------------------------------------------------------------------------

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .completeProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      context.go(AppRoutes.home);
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible guardar el perfil: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu perfil')),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state.isLoading ? null : _save,
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
