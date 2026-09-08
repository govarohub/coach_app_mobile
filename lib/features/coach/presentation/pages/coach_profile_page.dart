import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/presentation/providers/auth_state_provider.dart';
import '../../../profile/presentation/pages/profile_provider.dart';
import '../../../../app/router/app_routes.dart';
import '../../domain/entities/coach_profile.dart';
import 'coach_profile_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: coach_profile_page.dart
///
/// CK-010.11
///
/// Pantalla principal del perfil profesional del Coach.
/// ---------------------------------------------------------------------------

class CoachProfilePage extends ConsumerWidget {
  const CoachProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil profesional'),
      ),
      body: authState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(authStateProvider);
          },
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('No existe un usuario autenticado.'),
            );
          }

          final coachAsync = ref.watch(
            coachProfileProvider(user.id),
          );

          final profileAsync = ref.watch(profileProvider);

          return coachAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => _ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(
                  coachProfileProvider(user.id),
                );
              },
            ),
            data: (coach) {
              final profile = profileAsync.asData?.value;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(
                    coachProfileProvider(user.id),
                  );

                  ref.invalidate(profileProvider);

                  await ref.read(
                    coachProfileProvider(user.id).future,
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _ProfileHeader(
                      name: profile?.name ?? 'Coach',
                      email: profile?.email ?? '',
                      photoUrl: profile?.photoUrl,
                      verified: coach.verified,
                    ),
                    const SizedBox(height: 24),
                    _InformationCard(
                      title: 'Información profesional',
                      child: Column(
                        children: [
                          _InformationRow(
                            icon: Icons.workspace_premium_outlined,
                            label: 'Experiencia',
                            value:
                            '${coach.experienceYears} ${coach.experienceYears == 1 ? 'año' : 'años'}',
                          ),
                          _InformationRow(
                            icon: Icons.attach_money,
                            label: 'Tarifa por hora',
                            value:
                            '\$${coach.hourlyRate.toStringAsFixed(2)}',
                          ),
                          _InformationRow(
                            icon: Icons.star_outline,
                            label: 'Calificación',
                            value: coach.rating.toStringAsFixed(1),
                          ),
                          _InformationRow(
                            icon: Icons.circle_outlined,
                            label: 'Disponibilidad',
                            value: coach.available
                                ? 'Disponible'
                                : 'No disponible',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InformationCard(
                      title: 'Especialidades',
                      child: coach.specialties.isEmpty
                          ? const Text(
                        'Sin especialidades registradas.',
                      )
                          : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: coach.specialties
                            .map(
                              (specialty) => Chip(
                            label: Text(specialty),
                          ),
                        )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InformationCard(
                      title: 'Biografía profesional',
                      child: Text(
                        coach.bio?.trim().isNotEmpty == true
                            ? coach.bio!.trim()
                            : 'Sin biografía registrada.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InformationCard(
                      title: 'Ubicación profesional',
                      child: _LocationView(
                        location: coach.location,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await context.push<bool>(
                          AppRoutes.editCoachProfile,
                        );

                        if (result == true && context.mounted) {
                          ref.invalidate(
                            coachProfileProvider(user.id),
                          );

                          ref.invalidate(profileProvider);
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text(
                        'Editar perfil profesional',
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Encabezado del perfil profesional.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.verified,
  });

  final String name;
  final String email;
  final String? photoUrl;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null &&
        photoUrl!.trim().isNotEmpty;

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundImage: hasPhoto
              ? NetworkImage(photoUrl!)
              : null,
          child: hasPhoto
              ? null
              : const Icon(
            Icons.person,
            size: 48,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
        Chip(
          avatar: Icon(
            verified
                ? Icons.verified
                : Icons.info_outline,
            size: 18,
          ),
          label: Text(
            verified
                ? 'Coach verificado'
                : 'Verificación pendiente',
          ),
        ),
      ],
    );
  }
}

/// Tarjeta reutilizable para secciones del perfil.
class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Fila de información profesional.
class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Presentación de la ubicación profesional.
class _LocationView extends StatelessWidget {
  const _LocationView({
    required this.location,
  });

  final CoachLocation? location;

  @override
  Widget build(BuildContext context) {
    if (location == null) {
      return const Text(
        'Sin ubicación profesional registrada.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latitud: ${location!.latitude.toStringAsFixed(6)}',
        ),
        const SizedBox(height: 4),
        Text(
          'Longitud: ${location!.longitude.toStringAsFixed(6)}',
        ),
      ],
    );
  }
}

/// Estado de error de la pantalla.
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

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
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'No fue posible cargar el perfil profesional.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}