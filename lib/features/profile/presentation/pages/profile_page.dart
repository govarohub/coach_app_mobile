import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import 'profile_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: profile_page.dart
///
/// Pantalla principal del perfil del cliente.
///
/// CK-009.7:
/// - Muestra la fotografía actual.
/// - Permite agregar o cambiar la fotografía.
/// - Permite eliminar la fotografía.
/// - Consume ProfileNotifier mediante Riverpod.
/// - Permite regresar al menú principal mediante GoRouter.
/// ---------------------------------------------------------------------------

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        // Regresa directamente al menú principal mediante GoRouter.
        // ProfilePage es una ruta independiente dentro del router.
        leading: IconButton(
          tooltip: 'Regresar al inicio',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go(AppRoutes.home);
          },
        ),
        title: const Text('Mi perfil'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ProfileErrorView(
          message: error.toString(),
          onRetry: () {
            ref.read(profileProvider.notifier).reloadProfile();
          },
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No existe un perfil disponible.'));
          }

          return const _ProfileContent();
        },
      ),
    );
  }
}

/// Contenido principal del perfil.
class _ProfileContent extends ConsumerWidget {
  const _ProfileContent();

  /// Convierte errores técnicos en mensajes comprensibles para el usuario.
  String _profileImageErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('cancel')) {
      return 'No se seleccionó ninguna fotografía.';
    }

    if (message.contains('size') ||
        message.contains('tamaño') ||
        message.contains('large')) {
      return 'La fotografía supera el tamaño permitido.';
    }

    if (message.contains('type') ||
        message.contains('format') ||
        message.contains('image')) {
      return 'El formato de la fotografía no es válido.';
    }

    if (message.contains('permission') || message.contains('unauthorized')) {
      return 'No tienes permisos para actualizar la fotografía.';
    }

    return 'No fue posible actualizar la fotografía. '
        'Inténtalo nuevamente.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;

    if (profile == null) {
      return const SizedBox.shrink();
    }

    final profileNotifier = ref.read(profileProvider.notifier);

    // Estado independiente para las operaciones del avatar.
    final isLoading = ref.watch(profileImageProcessingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _ProfileAvatar(
            photoUrl: profile.photoUrl,
            isLoading: isLoading,

            // Selecciona una nueva fotografía y la guarda en Storage.
            onChangePhoto: () async {
              await profileNotifier.pickAndUploadProfileImage();

              if (!context.mounted) {
                return;
              }

              final state = ref.read(profileProvider);

              if (state.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_profileImageErrorMessage(state.error!)),
                  ),
                );
              }
            },

            // Elimina la fotografía después de confirmar la operación.
            onRemovePhoto: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Eliminar fotografía'),
                    content: const Text(
                      '¿Deseas eliminar tu fotografía de perfil?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  );
                },
              );

              if (confirmed != true) {
                return;
              }

              await profileNotifier.removeProfileImage();

              if (!context.mounted) {
                return;
              }

              final state = ref.read(profileProvider);

              if (state.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'No fue posible eliminar la fotografía: '
                      '${state.error}',
                    ),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // Abre la pantalla independiente para editar
          // los datos personales del perfil.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // La ruta se obtiene desde AppRoutes para mantener
                // la navegación centralizada del proyecto.
                context.push(AppRoutes.editProfile);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar perfil'),
            ),
          ),

          const SizedBox(height: 24),
          // La entidad ClientProfile utiliza "name".
          Text(
            profile.name,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),

          if (profile.phone != null && profile.phone!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(profile.phone!),
          ],
        ],
      ),
    );
  }
}

/// Avatar del cliente y acciones relacionadas.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.isLoading,
    required this.onChangePhoto,
    required this.onRemovePhoto,
  });

  final String? photoUrl;
  final bool isLoading;

  // Las operaciones interactúan con Firebase y son asíncronas.
  final FutureOr<void> Function() onChangePhoto;
  final FutureOr<void> Function() onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 64,
              backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
              child: hasPhoto ? null : const Icon(Icons.person, size: 64),
            ),

            // Indicador visual durante la carga o eliminación.
            if (isLoading)
              const SizedBox(
                width: 128,
                height: 128,
                child: CircularProgressIndicator(),
              ),
          ],
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              // Flutter espera un VoidCallback.
              // La operación real puede ejecutarse de forma asíncrona.
              onPressed: isLoading
                  ? null
                  : () {
                      onChangePhoto();
                    },
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(hasPhoto ? 'Cambiar foto' : 'Agregar foto'),
            ),

            if (hasPhoto)
              TextButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        onRemovePhoto();
                      },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
              ),
          ],
        ),
      ],
    );
  }
}

/// Vista de error del perfil.
class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No fue posible cargar el perfil.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
