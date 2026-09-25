import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../authentication/presentation/providers/auth_state_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// HomePage
///
/// CK-008.4
///
/// Dashboard principal.
///
/// Responsabilidades actuales:
/// - Mostrar información del usuario autenticado.
/// - Mostrar acciones principales según el rol del usuario.
/// - Mantener la navegación mediante AppRoutes.
/// - No ejecutar lógica de negocio directamente.
///
/// Las funcionalidades de cada módulo se implementarán en sus respectivos
/// CK. En esta etapa las acciones solamente preparan el acceso desde Home.
/// ---------------------------------------------------------------------------
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El Dashboard consume el estado de autenticación mediante Riverpod.
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          authState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (user) {
              if (user == null) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Mi perfil',
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  // El perfil se mantiene como acceso general de cuenta.
                  context.go(AppRoutes.profile);
                },
              );
            },
          ),
        ],
      ),
      body: authState.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No fue posible cargar la información del usuario.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        },
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'No hay un usuario autenticado.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return _AuthenticatedHomeContent(
            displayName: user.displayName,
            firstName: user.firstName,
            email: user.email,

            // El rol viene del documento users/{uid} de Firestore.
            role: user.role,
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Contenido principal del Dashboard.
/// ---------------------------------------------------------------------------
class _AuthenticatedHomeContent extends StatelessWidget {
  const _AuthenticatedHomeContent({
    required this.displayName,
    required this.firstName,
    required this.email,
    required this.role,
  });

  final String? displayName;
  final String? firstName;
  final String email;

  // Rol actual del usuario:
  // - client
  // - coach
  final String role;

  @override
  Widget build(BuildContext context) {
    final greetingName = _resolveGreetingName();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------------------
          // Encabezado del usuario.
          // ---------------------------------------------------------------
          _UserHeader(
            displayName: greetingName,
            email: email,
            onProfilePressed: () {
              context.go(AppRoutes.profile);
            },
          ),

          const SizedBox(height: 32),

          Text(
            '¿Qué deseas hacer?',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------------------
          // Acciones principales según el rol.
          //
          // Cliente:
          //   - Buscar un coach
          //   - Mis reservaciones
          //   - Mis favoritos
          //
          // Coach:
          //   - Mi perfil profesional
          // ---------------------------------------------------------------
          if (role == 'coach')
            const _CoachHomeActions()
          else
            const _HomeActions(),

          const SizedBox(height: 32),

          Text(
            'Tu cuenta',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UserInfoRow(
                    label: 'Nombre',
                    value: displayName?.trim().isNotEmpty == true
                        ? displayName!.trim()
                        : 'No configurado',
                  ),
                  const SizedBox(height: 12),
                  _UserInfoRow(
                    label: 'Correo',
                    value: email,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Determina el nombre utilizado en el encabezado.
  String _resolveGreetingName() {
    final completeName = displayName?.trim();

    if (completeName != null && completeName.isNotEmpty) {
      return completeName;
    }

    final name = firstName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return email;
  }
}

/// ---------------------------------------------------------------------------
/// Acciones principales del Dashboard del cliente.
/// ---------------------------------------------------------------------------
class _HomeActions extends StatelessWidget {
  const _HomeActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HomeActionCard(
          icon: Icons.search,
          title: 'Buscar un coach',
          description: 'Encuentra un coach de acuerdo con tus necesidades.',
          onPressed: () {
            // CK-012.11:
            // Abre la búsqueda como navegación hacia adelante mediante GoRouter.
            //
            // Se utiliza push para conservar el Dashboard en la pila de
            // navegación y permitir regresar posteriormente al Inicio.
            context.push(AppRoutes.coachSearch);
          },
        ),

        const SizedBox(height: 12),

        _HomeActionCard(
          icon: Icons.calendar_month_outlined,
          title: 'Mis reservaciones',
          description:
          'Consulta y administra tus próximas sesiones.',
          onPressed: () {
            // El calendario e historial serán implementados en CK-017.
            context.go(AppRoutes.reservations);
          },
        ),

        const SizedBox(height: 12),

        _HomeActionCard(
          icon: Icons.favorite_border,
          title: 'Mis favoritos',
          description: 'Accede rápidamente a tus coaches favoritos.',
          onPressed: () {
            context.push(AppRoutes.favorites);
          },
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Acciones principales del Dashboard del coach.
///
/// Actualmente el acceso principal del coach es su perfil profesional.
/// ---------------------------------------------------------------------------
class _CoachHomeActions extends StatelessWidget {
  const _CoachHomeActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HomeActionCard(
          icon: Icons.badge_outlined,
          title: 'Mi perfil profesional',
          description:
          'Consulta y administra tu información como coach.',
          onPressed: () {
            // El perfil profesional corresponde al CK-010.
            context.go(AppRoutes.coachProfile);
          },
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Tarjeta reutilizable para una acción principal.
/// ---------------------------------------------------------------------------
class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Icono representativo de la acción.
              CircleAvatar(
                radius: 24,
                child: Icon(icon),
              ),

              const SizedBox(width: 16),

              // Información de la acción.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Encabezado del usuario.
/// ---------------------------------------------------------------------------
class _UserHeader extends StatelessWidget {
  const _UserHeader({
    required this.displayName,
    required this.email,
    required this.onProfilePressed,
  });

  final String displayName;
  final String email;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          child: Text(
            _initial,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola,',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 2),

              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 2),

              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Mi perfil',
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: onProfilePressed,
        ),
      ],
    );
  }

  /// Obtiene la inicial mostrada en el avatar.
  String get _initial {
    final value = displayName.trim();

    if (value.isEmpty) {
      return '?';
    }

    return value.substring(0, 1).toUpperCase();
  }
}

/// ---------------------------------------------------------------------------
/// Fila reutilizable para información de cuenta.
/// ---------------------------------------------------------------------------
class _UserInfoRow extends StatelessWidget {
  const _UserInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}