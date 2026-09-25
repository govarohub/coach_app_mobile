import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/coach_profile.dart';
import '../../../favorites/presentation/favorites_provider.dart';

import 'coach_profile_provider.dart';
import 'coach_search_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo:
/// lib/features/coach/presentation/pages/coach_public_profile_page.dart
///
/// CK-013
///
/// Perfil público de un Coach.
///
/// CK-013.3:
/// - Obtiene y muestra el nombre real del Coach.
///
/// CK-013.4:
/// - Obtiene y muestra la fotografía pública del Coach.
///
/// CK-013.5:
/// - Muestra las especialidades.
///
/// CK-013.6:
/// - Muestra experiencia y biografía.
///
/// CK-013.7:
/// - Muestra tarifa y calificación.
///
/// CK-013.8:
/// - Muestra disponibilidad y verificación.
///
/// CK-013.9:
/// - Muestra ubicación profesional y calcula distancia.
///
/// CK-014.5:
/// - Permite agregar o quitar el Coach de favoritos.
///
/// IMPORTANTE:
/// - Se reutilizan los providers existentes.
/// - No se accede directamente a Firebase desde la UI.
/// - Favoritos utiliza FavoritesController.
/// ---------------------------------------------------------------------------

class CoachPublicProfilePage extends ConsumerStatefulWidget {
  const CoachPublicProfilePage({
    super.key,
    required this.coachId,
  });

  /// Identificador del Coach cuyo perfil público se consulta.
  final String coachId;

  @override
  ConsumerState<CoachPublicProfilePage> createState() =>
      _CoachPublicProfilePageState();
}

/// ---------------------------------------------------------------------------
/// Estado de la pantalla del perfil público.
/// ---------------------------------------------------------------------------

class _CoachPublicProfilePageState
    extends ConsumerState<CoachPublicProfilePage> {
  /// Posición actual del usuario.
  Position? _userPosition;

  /// Indica si se está obteniendo la ubicación.
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();

    // Obtiene la ubicación del usuario para calcular la distancia.
    _loadUserLocation();
  }

  /// -------------------------------------------------------------------------
  /// CK-013.9
  ///
  /// Obtiene la ubicación actual del usuario.
  /// -------------------------------------------------------------------------

  Future<void> _loadUserLocation() async {
    if (_loadingLocation) {
      return;
    }

    setState(() {
      _loadingLocation = true;
    });

    try {
      final position = await getCurrentUserPosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _userPosition = position;
      });
    } catch (_) {
      // La ubicación no es obligatoria para visualizar el perfil.

      if (!mounted) {
        return;
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  /// -------------------------------------------------------------------------
  /// CK-013.9
  ///
  /// Calcula la distancia entre el usuario y el Coach.
  /// -------------------------------------------------------------------------

  double? _getDistanceKm(CoachProfile coach) {
    final userPosition = _userPosition;

    if (userPosition == null) {
      return null;
    }

    return calculateCoachDistanceKm(
      userPosition: userPosition,
      coach: coach,
    );
  }

  /// -------------------------------------------------------------------------
  /// CK-014.5
  ///
  /// Construye el botón de favoritos.
  ///
  /// El estado visual depende de:
  ///
  /// favoriteStatusProvider(widget.coachId)
  ///
  /// La operación de agregar/quitar se ejecuta mediante:
  ///
  /// FavoritesController
  ///
  /// No existe acceso directo a Firestore desde esta pantalla.
  /// -------------------------------------------------------------------------

  Widget _buildFavoriteButton() {
    final favoriteAsync = ref.watch(
      favoriteStatusProvider(widget.coachId),
    );

    final controllerState = ref.watch(
      favoritesControllerProvider,
    );

    final isUpdating = controllerState.isLoading;

    final isFavorite = favoriteAsync.value ?? false;

    return IconButton(
      tooltip: isFavorite
          ? 'Quitar de favoritos'
          : 'Agregar a favoritos',
      onPressed: favoriteAsync.isLoading || isUpdating
          ? null
          : () async {
        try {
          await ref
              .read(
            favoritesControllerProvider.notifier,
          )
              .toggleFavorite(
            coachId: widget.coachId,
          );
        } catch (_) {
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No fue posible actualizar el favorito.',
              ),
            ),
          );
        }
      },
      icon: favoriteAsync.isLoading || isUpdating
          ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      )
          : Icon(
        isFavorite
            ? Icons.favorite
            : Icons.favorite_border,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // CK-013.2
    //
    // Obtiene el perfil profesional del Coach.
    // -------------------------------------------------------------------------

    final coachAsync = ref.watch(
      coachProfileProvider(widget.coachId),
    );

    // -------------------------------------------------------------------------
    // CK-013.3 / CK-013.4
    //
    // Obtiene la identidad pública del Coach.
    // -------------------------------------------------------------------------

    final identityAsync = ref.watch(
      coachPublicIdentityProvider(widget.coachId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Coach'),

        // ---------------------------------------------------------------------
        // CK-014.5
        //
        // Botón para agregar/quitar de favoritos.
        // ---------------------------------------------------------------------

        actions: [
          _buildFavoriteButton(),
        ],
      ),

      body: coachAsync.when(
        // ---------------------------------------------------------------------
        // Estado de carga.
        // ---------------------------------------------------------------------

        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },

        // ---------------------------------------------------------------------
        // Estado de error.
        // ---------------------------------------------------------------------

        error: (error, stackTrace) {
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

                  const Text(
                    'No fue posible cargar el perfil del Coach.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: () {
                      // Vuelve a consultar el perfil profesional.
                      ref.invalidate(
                        coachProfileProvider(widget.coachId),
                      );

                      // Vuelve a consultar la identidad pública.
                      ref.invalidate(
                        coachPublicIdentityProvider(
                          widget.coachId,
                        ),
                      );

                      // Vuelve a consultar el estado del favorito.
                      ref.invalidate(
                        favoriteStatusProvider(
                          widget.coachId,
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        },

        // ---------------------------------------------------------------------
        // Perfil recuperado correctamente.
        // ---------------------------------------------------------------------

        data: (coach) {
          final identity = identityAsync.value;

          // -------------------------------------------------------------------
          // Nombre público.
          // -------------------------------------------------------------------

          final displayName =
          identity?.name.trim().isNotEmpty == true
              ? identity!.name.trim()
              : 'Coach';

          // -------------------------------------------------------------------
          // Fotografía pública.
          // -------------------------------------------------------------------

          final photoUrl = identity?.photoUrl?.trim();

          final hasPhoto =
              photoUrl != null && photoUrl.isNotEmpty;

          // -------------------------------------------------------------------
          // Distancia.
          // -------------------------------------------------------------------

          final distanceKm = _getDistanceKm(coach);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ----------------------------------------------------------------
                // CK-013.4
                //
                // Fotografía pública.
                // ----------------------------------------------------------------

                Center(
                  child: CircleAvatar(
                    radius: 52,
                    backgroundImage: hasPhoto
                        ? NetworkImage(photoUrl)
                        : null,
                    child: hasPhoto
                        ? null
                        : const Icon(
                      Icons.person,
                      size: 52,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ----------------------------------------------------------------
                // CK-013.3
                //
                // Nombre.
                // ----------------------------------------------------------------

                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // ----------------------------------------------------------------
                // CK-013.8
                //
                // Disponibilidad.
                // ----------------------------------------------------------------

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      coach.available
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 18,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      coach.available
                          ? 'Disponible'
                          : 'No disponible',
                    ),
                  ],
                ),

                // ----------------------------------------------------------------
                // CK-013.8
                //
                // Verificación.
                // ----------------------------------------------------------------

                if (coach.verified) ...[
                  const SizedBox(height: 8),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 18,
                      ),

                      SizedBox(width: 6),

                      Text('Coach verificado'),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // ----------------------------------------------------------------
                // CK-013.6
                //
                // Biografía.
                // ----------------------------------------------------------------

                if (coach.bio != null &&
                    coach.bio!.trim().isNotEmpty) ...[
                  const Text(
                    'Sobre el Coach',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    coach.bio!.trim(),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],

                // ----------------------------------------------------------------
                // CK-013.5
                //
                // Especialidades.
                // ----------------------------------------------------------------

                const Text(
                  'Especialidades',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                if (coach.specialties.isEmpty)
                  const Text(
                    'No hay especialidades registradas.',
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: coach.specialties.map((specialty) {
                      return Chip(
                        label: Text(specialty),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),

                // ----------------------------------------------------------------
                // CK-013.6
                //
                // Experiencia.
                // ----------------------------------------------------------------

                _PublicProfileInfoCard(
                  icon: Icons.work_outline,
                  title: 'Experiencia',
                  value:
                  '${coach.experienceYears} '
                      '${coach.experienceYears == 1 ? 'año' : 'años'}',
                ),

                const SizedBox(height: 12),

                // ----------------------------------------------------------------
                // CK-013.7
                //
                // Calificación.
                // ----------------------------------------------------------------

                _PublicProfileInfoCard(
                  icon: Icons.star_outline,
                  title: 'Calificación',
                  value: coach.rating.toStringAsFixed(1),
                ),

                const SizedBox(height: 12),

                // ----------------------------------------------------------------
                // CK-013.7
                //
                // Tarifa.
                // ----------------------------------------------------------------

                _PublicProfileInfoCard(
                  icon: Icons.payments_outlined,
                  title: 'Tarifa por hora',
                  value:
                  '\$${coach.hourlyRate.toStringAsFixed(2)}',
                ),

                const SizedBox(height: 12),

                // ----------------------------------------------------------------
                // CK-013.9
                //
                // Ubicación profesional.
                // ----------------------------------------------------------------

                if (coach.location != null)
                  _PublicProfileInfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Ubicación profesional',
                    value:
                    '${coach.location!.latitude.toStringAsFixed(4)}, '
                        '${coach.location!.longitude.toStringAsFixed(4)}',
                  ),

                // ----------------------------------------------------------------
                // CK-013.9
                //
                // Distancia.
                // ----------------------------------------------------------------

                if (distanceKm != null) ...[
                  const SizedBox(height: 12),

                  _PublicProfileInfoCard(
                    icon: Icons.social_distance_outlined,
                    title: 'Distancia',
                    value:
                    '${distanceKm.toStringAsFixed(1)} km',
                  ),
                ],

                // ----------------------------------------------------------------
                // Estado de ubicación.
                // ----------------------------------------------------------------

                if (_loadingLocation) ...[
                  const SizedBox(height: 16),

                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Tarjeta reutilizable para información profesional.
/// ---------------------------------------------------------------------------

class _PublicProfileInfoCard extends StatelessWidget {
  const _PublicProfileInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                    Theme.of(context).textTheme.bodySmall,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}