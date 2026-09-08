import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo:
/// edit_profile_page.dart
///
/// CK-009.4
///
/// Página destinada a la edición de los datos personales del perfil.
///
/// Responsabilidades:
/// - Mostrar los datos actuales del perfil.
/// - Permitir modificar nombre y teléfono.
/// - Validar los datos antes de guardarlos.
/// - Enviar los cambios al ProfileNotifier.
///
/// Esta página NO accede directamente a Firebase.
/// La persistencia se realiza mediante:
///
/// UI
///  ↓
/// ProfileNotifier
///  ↓
/// ClientProfileRepository
///  ↓
/// FirebaseProfileDataSource
///  ↓
/// Cloud Firestore
/// ---------------------------------------------------------------------------

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

/// ---------------------------------------------------------------------------
/// Estado de la página de edición.
/// ---------------------------------------------------------------------------
class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  /// Clave utilizada para validar el formulario.
  final _formKey = GlobalKey<FormState>();

  /// Controlador del nombre.
  late final TextEditingController _nameController;

  /// Controlador del teléfono.
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    // Obtenemos el estado actual del perfil.
    //
    // El perfil ya fue cargado por profileProvider antes de entrar
    // normalmente a esta pantalla.
    final profile = ref.read(profileProvider).value;

    // Inicializamos los campos con los datos actuales.
    _nameController = TextEditingController(
      text: profile?.name ?? '',
    );

    _phoneController = TextEditingController(
      text: profile?.phone ?? '',
    );
  }

  @override
  void dispose() {
    // Liberamos los controladores cuando la página deja de existir.
    _nameController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  /// -------------------------------------------------------------------------
  /// Guarda los cambios del perfil.
  /// -------------------------------------------------------------------------
  Future<void> _saveProfile() async {
    // Primero validamos todos los campos del formulario.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Enviamos los datos al notifier.
    //
    // El notifier se encarga de obtener el usuario autenticado
    // y ejecutar la actualización mediante el Repository.
    await ref.read(profileProvider.notifier).updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    // Leemos el resultado final del provider.
    final state = ref.read(profileProvider);

    if (state.hasError) {
      // El error será gestionado posteriormente de forma más específica
      // dentro de CK-009.6.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible actualizar el perfil: ${state.error}',
          ),
        ),
      );

      return;
    }

    // Si la actualización terminó correctamente, regresamos
    // a la pantalla anterior.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil actualizado correctamente.'),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Observamos el estado actual del perfil para conocer si
    // la operación de actualización está en curso.
    final profileAsync = ref.watch(profileProvider);

    final isLoading = profileAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,

          // La validación se muestra mientras el usuario interactúa
          // con los campos.
          autovalidateMode: AutovalidateMode.onUserInteraction,

          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              /// -------------------------------------------------------------
              /// NOMBRE
              /// -------------------------------------------------------------
              TextFormField(
                controller: _nameController,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ingresa tu nombre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';

                  if (name.isEmpty) {
                    return 'Ingresa tu nombre.';
                  }

                  if (name.length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// -------------------------------------------------------------
              /// TELÉFONO
              /// -------------------------------------------------------------
              TextFormField(
                controller: _phoneController,
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: 'Ingresa tu teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  final phone = value?.replaceAll(RegExp(r'\s+'), '') ?? '';

                  // El teléfono es opcional.
                  if (phone.isEmpty) {
                    return null;
                  }

                  // Si se proporciona, únicamente aceptamos números.
                  if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
                    return 'El teléfono solo debe contener números.';
                  }

                  // Para el perfil de la aplicación utilizamos
                  // un mínimo de 10 dígitos.
                  if (phone.length < 10) {
                    return 'El teléfono debe tener al menos 10 dígitos.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 28),

              /// -------------------------------------------------------------
              /// BOTÓN GUARDAR
              /// -------------------------------------------------------------
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                FilledButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar cambios'),
                ),

              const SizedBox(height: 12),

              /// -------------------------------------------------------------
              /// BOTÓN CANCELAR
              /// -------------------------------------------------------------
              OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}