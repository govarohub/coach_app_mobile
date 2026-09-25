import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';

import '../../domain/entities/favorite_coach.dart';
import '../favorites_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo:
/// lib/features/favorites/presentation/pages/favorites_page.dart
///
/// CK-014.6
/// Pantalla "Mis Favoritos".
///
/// CK-014.7
/// Navegación desde un favorito hacia el Perfil Público del Coach.
///
/// CK-014.8
/// Estados de carga, error y lista vacía.
///
/// Responsabilidades:
/// - Obtener favoritos mediante favoritesProvider.
/// - Mostrar estados de carga, error y vacío.
/// - Mostrar la información pública del Coach.
/// - Permitir eliminar un favorito mediante FavoritesController.
/// - Navegar al Perfil Público mediante el router centralizado.
///
/// IMPORTANTE:
/// - La pantalla no accede directamente a Firestore.
/// - No contiene lógica de persistencia.
/// - No crea una nueva fuente de datos.
/// ---------------------------------------------------------------------------
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// -----------------------------------------------------------------------
    /// CK-014.8
    ///
    /// El estado de la consulta se controla mediante AsyncValue.
    ///
    /// De esta manera la pantalla mantiene separados:
    /// - carga
    /// - error
    /// - datos
    /// -----------------------------------------------------------------------
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
      ),
      body: favoritesAsync.when(
        /// -------------------------------------------------------------------
        /// CK-014.8
        ///
        /// Estado de carga inicial.
        /// -------------------------------------------------------------------
        loading: () {
          return const _FavoritesLoadingState();
        },

        /// -------------------------------------------------------------------
        /// CK-014.8
        ///
        /// Estado de error.
        ///
        /// Se permite volver a ejecutar la consulta sin abandonar la pantalla.
        /// -------------------------------------------------------------------
        error: (error, stackTrace) {
          return _FavoritesErrorState(
            onRetry: () {
              /// Vuelve a ejecutar el provider existente.
              ref.invalidate(favoritesProvider);
            },
          );
        },

        /// -------------------------------------------------------------------
        /// CK-014.8
        ///
        /// Estado con datos.
        ///
        /// Si la colección no contiene favoritos, se muestra el estado vacío.
        /// -------------------------------------------------------------------
        data: (favorites) {
          if (favorites.isEmpty) {
            return const _FavoritesEmptyState();
          }

          /// ---------------------------------------------------------------
          /// CK-014.6
          ///
          /// Permite actualizar manualmente la lista mediante gesto de
          /// desplazamiento hacia abajo.
          /// ---------------------------------------------------------------
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(favoritesProvider);

              /// Espera a que termine la nueva consulta para que el gesto
              /// de actualización tenga un ciclo completo.
              await ref.read(favoritesProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                final favorite = favorites[index];

                return _FavoriteCoachCard(
                  favorite: favorite,
                  onRemove: () async {
                    await _removeFavorite(
                      context: context,
                      ref: ref,
                      coachId: favorite.coachId,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// CK-014.6
  ///
  /// Elimina un Coach de favoritos utilizando el Controller existente.
  ///
  /// La pantalla solamente solicita la operación:
  /// no realiza ninguna escritura directa en Firestore.
  /// -------------------------------------------------------------------------
  Future<void> _removeFavorite({
    required BuildContext context,
    required WidgetRef ref,
    required String coachId,
  }) async {
    try {
      await ref.read(
        favoritesControllerProvider.notifier,
      ).removeFavorite(
        coachId: coachId,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coach eliminado de favoritos.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible eliminar el favorito.',
          ),
        ),
      );
    }
  }
}

/// ---------------------------------------------------------------------------
/// CK-014.8
///
/// Estado de carga de "Mis Favoritos".
///
/// Se mantiene como widget independiente para que el estado visual no se
/// mezcle con la lógica de consulta.
/// ---------------------------------------------------------------------------
class _FavoritesLoadingState extends StatelessWidget {
  const _FavoritesLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Tarjeta de un Coach favorito.
/// ---------------------------------------------------------------------------
class _FavoriteCoachCard extends StatelessWidget {
  const _FavoriteCoachCard({
    required this.favorite,
    required this.onRemove,
  });

  final FavoriteCoach favorite;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final profile = favorite.profile;
    final identity = favorite.identity;

    /// Utiliza la primera especialidad disponible.
    ///
    /// Si el perfil no contiene especialidades, se muestra un texto neutro
    /// en lugar de inventar información.
    final specialty = profile.specialties.isNotEmpty
        ? profile.specialties.first
        : 'Especialidad no disponible';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        /// -------------------------------------------------------------------
        /// CK-014.7
        ///
        /// Abre el Perfil Público utilizando la navegación centralizada.
        ///
        /// Se envía el coachId del favorito, que corresponde al identificador
        /// del Coach y no al identificador del cliente autenticado.
        /// -------------------------------------------------------------------
        onTap: () {
          context.pushNamed(
            RouteNames.coachPublicProfile,
            pathParameters: {
              'coachId': favorite.coachId,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// -------------------------------------------------------------
              /// Fotografía pública del Coach.
              /// -------------------------------------------------------------
              _CoachPhoto(
                photoUrl: identity.photoUrl,
                name: identity.name,
              ),

              const SizedBox(width: 16),

              /// -------------------------------------------------------------
              /// Información pública y profesional.
              /// -------------------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      identity.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '\$${profile.hourlyRate.toStringAsFixed(2)}/h',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          profile.available
                              ? Icons.check_circle_outline
                              : Icons.schedule_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.available
                              ? 'Disponible'
                              : 'No disponible',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// -------------------------------------------------------------
              /// Acción para quitar el Coach de favoritos.
              ///
              /// El botón detiene la propagación del toque de la tarjeta
              /// porque su propia acción se ejecuta independientemente.
              /// -------------------------------------------------------------
              IconButton(
                tooltip: 'Quitar de favoritos',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.favorite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Fotografía pública del Coach.
///
/// Si no existe una URL válida, se muestra la inicial del nombre.
/// No se generan URLs ni información ficticia.
/// ---------------------------------------------------------------------------
class _CoachPhoto extends StatelessWidget {
  const _CoachPhoto({
    required this.photoUrl,
    required this.name,
  });

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final normalizedPhotoUrl = photoUrl?.trim();

    if (normalizedPhotoUrl == null || normalizedPhotoUrl.isEmpty) {
      return CircleAvatar(
        radius: 32,
        child: Text(
          _initial,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return CircleAvatar(
      radius: 32,
      backgroundImage: NetworkImage(normalizedPhotoUrl),

      /// Si la imagen remota falla, se conserva la tarjeta funcional.
      onBackgroundImageError: (_, _) {},

      child: const SizedBox.shrink(),
    );
  }

  /// Obtiene la primera letra del nombre para el avatar alternativo.
  String get _initial {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      return '?';
    }

    return normalizedName.substring(0, 1).toUpperCase();
  }
}

/// ---------------------------------------------------------------------------
/// CK-014.8
///
/// Estado vacío.
///
/// Se muestra cuando la consulta fue correcta pero el usuario todavía no
/// tiene Coaches registrados como favoritos.
/// ---------------------------------------------------------------------------
class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes Coaches favoritos',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega Coaches a favoritos desde su perfil público.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// CK-014.8
///
/// Estado de error.
///
/// El mensaje mostrado al usuario es funcional y no expone la excepción
/// técnica ni el stack trace.
/// ---------------------------------------------------------------------------
class _FavoritesErrorState extends StatelessWidget {
  const _FavoritesErrorState({
    required this.onRetry,
  });

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
            const SizedBox(height: 16),
            Text(
              'No fue posible cargar tus favoritos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Verifica tu conexión a Internet e inténtalo nuevamente.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}