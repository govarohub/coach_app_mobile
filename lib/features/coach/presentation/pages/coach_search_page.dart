import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../domain/entities/coach_profile.dart';
import 'coach_search_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: coach_search_page.dart
///
/// CK-012
///
/// Pantalla de búsqueda de Coaches.
///
/// CK-012.10:
/// Estados de carga, vacío y error.
///
/// CK-013.10:
/// Navegación desde los resultados de búsqueda hacia el perfil público
/// del Coach seleccionado.
/// ---------------------------------------------------------------------------

class CoachSearchPage extends ConsumerStatefulWidget {
  const CoachSearchPage({super.key});

  @override
  ConsumerState<CoachSearchPage> createState() => _CoachSearchPageState();
}

class _CoachSearchPageState extends ConsumerState<CoachSearchPage> {
  /// Controla el texto utilizado para buscar por especialidad.
  final TextEditingController _searchController = TextEditingController();

  /// Indica si solamente se muestran Coaches disponibles.
  bool _onlyAvailable = false;

  /// Indica si solamente se muestran Coaches verificados.
  bool _onlyVerified = false;

  /// Posición actual del usuario.
  ///
  /// Cuando existe, permite calcular y ordenar los Coaches
  /// por distancia.
  Position? _userPosition;

  /// Indica si se está obteniendo la ubicación del usuario.
  bool _loadingLocation = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// -------------------------------------------------------------------------
  /// CK-012.6
  ///
  /// Obtiene la ubicación actual del usuario utilizando Geolocator.
  ///
  /// Los errores se controlan desde la pantalla para mostrar un mensaje
  /// comprensible al usuario.
  /// -------------------------------------------------------------------------
  Future<void> _getUserLocation() async {
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
    } catch (error) {
      if (!mounted) {
        return;
      }

      /// CK-012.10:
      /// El error de ubicación no debe romper la pantalla.
      /// Se informa al usuario mediante un mensaje temporal.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getLocationErrorMessage(error),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  /// -------------------------------------------------------------------------
  /// CK-012.10
  ///
  /// Convierte los errores conocidos de ubicación en mensajes comprensibles.
  ///
  /// No mostramos al usuario el texto técnico completo de la excepción.
  /// -------------------------------------------------------------------------
  String _getLocationErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '');

    if (message.contains('desactivado')) {
      return 'Activa el servicio de ubicación para continuar.';
    }

    if (message.contains('rechazado permanentemente')) {
      return 'El permiso de ubicación está bloqueado. '
          'Actívalo desde los ajustes del dispositivo.';
    }

    if (message.contains('rechazado')) {
      return 'Se necesita permiso de ubicación para calcular las distancias.';
    }

    return 'No fue posible obtener tu ubicación. Intenta nuevamente.';
  }

  /// -------------------------------------------------------------------------
  /// CK-012.10
  ///
  /// Estado de carga inicial de la búsqueda.
  /// -------------------------------------------------------------------------
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// -------------------------------------------------------------------------
  /// CK-012.10
  ///
  /// Estado de error al cargar los Coaches desde Firestore.
  ///
  /// Permite volver a ejecutar la consulta sin salir de la pantalla.
  /// -------------------------------------------------------------------------
  Widget _buildErrorState(Object error) {
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
              'No fue posible cargar los Coaches.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifica tu conexión a Internet e inténtalo nuevamente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                /// Vuelve a ejecutar la consulta existente.
                ref.invalidate(coachSearchProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// CK-012.10
  ///
  /// Estado vacío cuando los filtros no producen resultados.
  /// -------------------------------------------------------------------------
  Widget _buildEmptyResultsState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No se encontraron Coaches.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Prueba con otra especialidad o modifica los filtros seleccionados.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Consulta los Coaches mediante el provider existente.
    final coachesAsync = ref.watch(coachSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Coach'),
      ),

      /// CK-012.10:
      /// El estado principal de la consulta se controla directamente
      /// mediante AsyncValue del FutureProvider.
      body: coachesAsync.when(
        /// ---------------------------------------------------------------
        /// ESTADO: CARGANDO
        /// ---------------------------------------------------------------
        loading: _buildLoadingState,

        /// ---------------------------------------------------------------
        /// ESTADO: ERROR
        /// ---------------------------------------------------------------
        error: (error, stackTrace) {
          return _buildErrorState(error);
        },

        /// ---------------------------------------------------------------
        /// ESTADO: DATOS
        /// ---------------------------------------------------------------
        data: (coaches) {
          /// CK-012.8:
          /// Aplica todos los filtros y el ordenamiento existentes.
          final searchResult = applyCoachSearchFilters(
            coaches: coaches,
            specialty: _searchController.text,
            onlyAvailable: _onlyAvailable,
            onlyVerified: _onlyVerified,
            userPosition: _userPosition,
          );

          final filteredCoaches = searchResult.coaches;
          final coachDistances = searchResult.distances;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    /// ---------------------------------------------------
                    /// Campo de búsqueda.
                    /// ---------------------------------------------------
                    TextField(
                      controller: _searchController,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: 'Buscar Coach',
                        hintText: 'Especialidad',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// ---------------------------------------------------
                    /// Filtro de disponibilidad.
                    /// ---------------------------------------------------
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Solo disponibles'),
                      value: _onlyAvailable,
                      onChanged: (value) {
                        setState(() {
                          _onlyAvailable = value;
                        });
                      },
                    ),

                    /// ---------------------------------------------------
                    /// Filtro de verificación.
                    /// ---------------------------------------------------
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Solo verificados'),
                      value: _onlyVerified,
                      onChanged: (value) {
                        setState(() {
                          _onlyVerified = value;
                        });
                      },
                    ),

                    /// ---------------------------------------------------
                    /// Ubicación del usuario.
                    ///
                    /// CK-012.10:
                    /// Mientras se obtiene la ubicación, el botón queda
                    /// deshabilitado y muestra el estado de carga.
                    /// ---------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loadingLocation
                            ? null
                            : _getUserLocation,
                        icon: _loadingLocation
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.my_location),
                        label: Text(
                          _loadingLocation
                              ? 'Obteniendo ubicación...'
                              : _userPosition == null
                              ? 'Usar mi ubicación'
                              : 'Actualizar mi ubicación',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// -----------------------------------------------------------
              /// Contador de resultados.
              /// -----------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filteredCoaches.length} Coach'
                        '${filteredCoaches.length == 1 ? '' : 'es'} '
                        'encontrado'
                        '${filteredCoaches.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              /// -----------------------------------------------------------
              /// RESULTADOS / ESTADO VACÍO.
              /// -----------------------------------------------------------
              Expanded(
                child: filteredCoaches.isEmpty
                    ? _buildEmptyResultsState()
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24,
                  ),
                  itemCount: filteredCoaches.length,
                  itemBuilder: (context, index) {
                    final coach = filteredCoaches[index];

                    return _CoachResultCard(
                      coach: coach,
                      distanceKm: coachDistances[coach.coachId],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// CK-012.9
///
/// Tarjeta de resultado de Coach.
///
/// CK-013.10:
/// La tarjeta permite seleccionar un Coach y navegar a su perfil público.
///
/// Se mantiene dentro del mismo archivo para respetar la estructura actual
/// y evitar crear una nueva carpeta o archivo innecesario.
/// ---------------------------------------------------------------------------
class _CoachResultCard extends StatelessWidget {
  const _CoachResultCard({
    required this.coach,
    required this.distanceKm,
  });

  final CoachProfile coach;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        /// -----------------------------------------------------------------
        /// CK-013.10
        ///
        /// Abre el perfil público del Coach seleccionado.
        ///
        /// Se utiliza el `coachId` real de la entidad CoachProfile.
        /// No se utiliza un identificador fijo ni el usuario autenticado.
        /// -----------------------------------------------------------------
        onTap: () {
          context.pushNamed(
            RouteNames.coachPublicProfile,
            pathParameters: {
              'coachId': coach.coachId,
            },
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Encabezado de la tarjeta.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Avatar visual.
                  CircleAvatar(
                    radius: 28,
                    child: const Icon(
                      Icons.person,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// Información principal del Coach.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Coach',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            /// Indicador de Coach verificado.
                            if (coach.verified)
                              const Icon(
                                Icons.verified,
                                size: 20,
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        /// Estado de disponibilidad.
                        Row(
                          children: [
                            Icon(
                              coach.available
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              coach.available
                                  ? 'Disponible'
                                  : 'No disponible',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// Especialidades.
              if (coach.specialties.isNotEmpty) ...[
                const Text(
                  'Especialidades',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: coach.specialties.map((specialty) {
                    return Chip(
                      label: Text(specialty),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              /// Experiencia y calificación.
              Row(
                children: [
                  Expanded(
                    child: _CoachInfoItem(
                      icon: Icons.work_outline,
                      label: 'Experiencia',
                      value:
                      '${coach.experienceYears} '
                          '${coach.experienceYears == 1 ? 'año' : 'años'}',
                    ),
                  ),
                  Expanded(
                    child: _CoachInfoItem(
                      icon: Icons.star_outline,
                      label: 'Calificación',
                      value: coach.rating.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// Tarifa y distancia.
              Row(
                children: [
                  Expanded(
                    child: _CoachInfoItem(
                      icon: Icons.payments_outlined,
                      label: 'Tarifa por hora',
                      value:
                      '\$${coach.hourlyRate.toStringAsFixed(2)}',
                    ),
                  ),
                  Expanded(
                    child: _CoachInfoItem(
                      icon: Icons.location_on_outlined,
                      label: 'Distancia',
                      value: distanceKm == null
                          ? 'No disponible'
                          : '${distanceKm!.toStringAsFixed(1)} km',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Elemento de información utilizado por la tarjeta del Coach.
/// ---------------------------------------------------------------------------
class _CoachInfoItem extends StatelessWidget {
  const _CoachInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}