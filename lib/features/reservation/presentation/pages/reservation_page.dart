import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../coach/presentation/pages/coach_profile_provider.dart';
import '../../../coach/domain/entities/coach_schedule.dart';
import '../../../coach/presentation/pages/coach_schedule_provider.dart';
import 'reservation_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: reservation_page.dart
///
/// CK-016.7 / CK-016.8 / CK-016.9 / CK-016.10
///
/// Responsabilidades:
/// - Mostrar información del Coach.
/// - Mostrar únicamente horarios disponibles.
/// - Permitir seleccionar un horario.
/// - Crear la reservación mediante ReservationController.
/// - Mostrar estados de carga, error y vacío.
///
/// IMPORTANTE:
/// - La pantalla no accede directamente a Firestore.
/// - La pantalla no crea documentos.
/// - La persistencia se realiza mediante:
///   Provider -> Repository -> DataSource.
/// ---------------------------------------------------------------------------
class ReservationPage extends ConsumerStatefulWidget {
  const ReservationPage({
    super.key,
    required this.coachId,
  });

  /// Identificador del Coach cuya sesión se desea reservar.
  final String coachId;

  @override
  ConsumerState<ReservationPage> createState() =>
      _ReservationPageState();
}

/// ---------------------------------------------------------------------------
/// Estado de la pantalla de reservación.
/// ---------------------------------------------------------------------------
class _ReservationPageState
    extends ConsumerState<ReservationPage> {
  /// Horario seleccionado por el cliente.
  CoachSchedule? _selectedSchedule;

  @override
  Widget build(BuildContext context) {
    /// -----------------------------------------------------------------------
    /// Consulta únicamente los horarios disponibles del Coach.
    ///
    /// CK-016:
    /// La reservación solamente puede utilizar horarios cuyo estado sea
    /// `available`.
    ///
    /// Los horarios `reserved` y `blocked` quedan excluidos desde la
    /// consulta del Repository.
    /// -----------------------------------------------------------------------
    final schedulesAsync = ref.watch(
      coachAvailableSchedulesProvider(
        widget.coachId,
      ),
    );

    /// -----------------------------------------------------------------------
    /// Información profesional del Coach.
    /// -----------------------------------------------------------------------
    final coachAsync = ref.watch(
      coachProfileProvider(
        widget.coachId,
      ),
    );

    /// -----------------------------------------------------------------------
    /// Estado de la operación de reservación.
    ///
    /// AsyncLoading:
    ///     reservación en proceso.
    ///
    /// AsyncError:
    ///     ocurrió un error durante la operación.
    ///
    /// AsyncData:
    ///     operación finalizada correctamente.
    /// -----------------------------------------------------------------------
    final reservationState = ref.watch(
      reservationControllerProvider,
    );

    final isCreating = reservationState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reservar sesión',
        ),
      ),

      /// ---------------------------------------------------------------------
      /// Estado principal de los horarios.
      /// ---------------------------------------------------------------------
      body: schedulesAsync.when(
        /// -------------------------------------------------------------------
        /// CK-016.10
        ///
        /// Estado de carga de horarios.
        /// -------------------------------------------------------------------
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },

        /// -------------------------------------------------------------------
        /// CK-016.10
        ///
        /// Error al consultar los horarios.
        /// -------------------------------------------------------------------
        error: (error, stackTrace) {
          return _ReservationErrorState(
            message: 'No fue posible cargar los horarios.',
            onRetry: () {
              /// Reintenta únicamente la consulta de horarios disponibles.
              ref.invalidate(
                coachAvailableSchedulesProvider(
                  widget.coachId,
                ),
              );
            },
          );
        },

        /// -------------------------------------------------------------------
        /// Datos obtenidos correctamente.
        /// -------------------------------------------------------------------
        data: (schedules) {
          /// -----------------------------------------------------------------
          /// CK-016.10
          ///
          /// Estado vacío.
          ///
          /// Al utilizar coachAvailableSchedulesProvider, esta condición
          /// significa que no existe ningún horario con status `available`.
          ///
          /// Los horarios `blocked` y `reserved` no llegan hasta aquí.
          /// -----------------------------------------------------------------
          if (schedules.isEmpty) {
            return const _ReservationEmptyState();
          }

          /// -----------------------------------------------------------------
          /// Consulta del perfil del Coach.
          /// -----------------------------------------------------------------
          return coachAsync.when(
            /// -----------------------------------------------------------------
            /// Estado de carga del perfil.
            /// -----------------------------------------------------------------
            loading: () {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },

            /// -----------------------------------------------------------------
            /// Error del perfil.
            /// -----------------------------------------------------------------
            error: (error, stackTrace) {
              return _ReservationErrorState(
                message:
                'No fue posible cargar la información del Coach.',
                onRetry: () {
                  /// Reintenta únicamente el perfil del Coach.
                  ref.invalidate(
                    coachProfileProvider(
                      widget.coachId,
                    ),
                  );
                },
              );
            },

            /// -----------------------------------------------------------------
            /// Perfil y horarios disponibles.
            /// -----------------------------------------------------------------
            data: (coach) {
              return Column(
                children: [
                  /// ---------------------------------------------------------
                  /// Tarifa del Coach.
                  /// ---------------------------------------------------------
                  _CoachRateCard(
                    hourlyRate: coach.hourlyRate,
                  ),

                  /// ---------------------------------------------------------
                  /// Lista de horarios disponibles.
                  /// ---------------------------------------------------------
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: schedules.length,
                      separatorBuilder: (
                          context,
                          index,
                          ) {
                        return const SizedBox(
                          height: 12,
                        );
                      },
                      itemBuilder: (
                          context,
                          index,
                          ) {
                        final schedule = schedules[index];

                        final isSelected =
                            _selectedSchedule?.scheduleId ==
                                schedule.scheduleId;

                        return _ScheduleCard(
                          schedule: schedule,
                          selected: isSelected,

                          /// Mientras se crea una reservación
                          /// no permitimos cambiar de horario.
                          enabled: !isCreating,

                          onTap: () {
                            if (isCreating) {
                              return;
                            }

                            setState(() {
                              _selectedSchedule = schedule;
                            });
                          },
                        );
                      },
                    ),
                  ),

                  /// ---------------------------------------------------------
                  /// Área inferior de la reservación.
                  /// ---------------------------------------------------------
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          /// -------------------------------------------------
                          /// CK-016.10
                          ///
                          /// Error durante la creación de la reservación.
                          ///
                          /// El Controller conserva el estado AsyncError.
                          /// La UI únicamente lo presenta.
                          /// -------------------------------------------------
                          if (reservationState.hasError) ...[
                            const _ReservationActionErrorState(
                              message:
                              'No fue posible crear la reservación.',
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                          ],

                          /// -------------------------------------------------
                          /// Botón para crear la reservación.
                          /// -------------------------------------------------
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                              _selectedSchedule == null ||
                                  isCreating
                                  ? null
                                  : () async {
                                /// El horario seleccionado
                                /// se pasa completo al método.
                                await _createPendingReservation(
                                  schedule:
                                  _selectedSchedule!,
                                  amount:
                                  coach.hourlyRate,
                                );
                              },

                              /// ------------------------------------------------
                              /// Indicador de carga durante la operación.
                              /// ------------------------------------------------
                              icon: isCreating
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(
                                Icons.event_available,
                              ),

                              /// ------------------------------------------------
                              /// Texto dinámico del botón.
                              /// ------------------------------------------------
                              label: Text(
                                isCreating
                                    ? 'Creando reservación...'
                                    : 'Continuar con la reservación',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // CK-016.8 / CK-016.9
  //
  // Crea la reservación y actualiza el horario seleccionado.
  //
  // Flujo:
  //
  // 1. ReservationController crea la reservación con:
  //      status = pending
  //
  // 2. El mismo Controller actualiza el horario:
  //      status = reserved
  //
  // La pantalla no accede directamente a Firebase.
  // -------------------------------------------------------------------------
  Future<void> _createPendingReservation({
    required CoachSchedule schedule,
    required double amount,
  }) async {
    try {
      /// ---------------------------------------------------------------
      /// Ejecuta la operación mediante el Controller existente.
      /// ---------------------------------------------------------------
      final reservationId = await ref
          .read(
        reservationControllerProvider.notifier,
      )
          .createPendingReservationAndReserveSchedule(
        /// Coach asociado al horario.
        coachId: widget.coachId,

        /// Horario seleccionado.
        scheduleId: schedule.scheduleId,

        /// Tarifa actual de la sesión.
        amount: amount,
      );

      if (!mounted) {
        return;
      }

      /// ---------------------------------------------------------------
      /// Confirmación visual de la operación.
      /// ---------------------------------------------------------------
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reservación creada: $reservationId',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      /// ---------------------------------------------------------------
      /// El Controller ya conserva AsyncError.
      ///
      /// Aquí solamente mostramos una confirmación visual del error.
      /// ---------------------------------------------------------------
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible crear la reservación.',
          ),
        ),
      );
    }
  }
}

/// ---------------------------------------------------------------------------
/// Tarjeta que muestra la tarifa del Coach.
/// ---------------------------------------------------------------------------
class _CoachRateCard extends StatelessWidget {
  const _CoachRateCard({
    required this.hourlyRate,
  });

  final double hourlyRate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        4,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.attach_money,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarifa por sesión',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    '\$${hourlyRate.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge,
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

/// ---------------------------------------------------------------------------
/// Tarjeta de horario disponible.
/// ---------------------------------------------------------------------------
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final CoachSchedule schedule;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: enabled,
        onTap: onTap,

        /// Indicador visual de selección.
        leading: Icon(
          selected
              ? Icons.radio_button_checked
              : Icons.radio_button_off,
        ),

        /// Fecha del horario.
        title: Text(
          _formatDate(schedule.date),
        ),

        /// Hora inicial y final.
        subtitle: Text(
          '${schedule.startTime} - ${schedule.endTime}',
        ),

        /// Confirmación visual del horario seleccionado.
        trailing: selected
            ? const Icon(
          Icons.check_circle,
        )
            : null,
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// Formato visual de la fecha.
  /// -------------------------------------------------------------------------
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year}';
  }
}

/// ---------------------------------------------------------------------------
/// CK-016.10
///
/// Estado vacío de horarios.
///
/// Se muestra cuando el Coach no tiene horarios disponibles para reservar.
/// ---------------------------------------------------------------------------
class _ReservationEmptyState extends StatelessWidget {
  const _ReservationEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 64,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'No hay horarios disponibles.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Actualmente no hay sesiones disponibles para reservar.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// CK-016.10
///
/// Estado de error de carga de información.
/// ---------------------------------------------------------------------------
class _ReservationErrorState extends StatelessWidget {
  const _ReservationErrorState({
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
            const SizedBox(
              height: 16,
            ),
            Text(
              'No fue posible cargar la información.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text(
                'Reintentar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// CK-016.10
///
/// Estado de error de la operación de reservación.
///
/// Este estado se muestra dentro de la pantalla sin sustituir
/// la lista de horarios.
/// ---------------------------------------------------------------------------
class _ReservationActionErrorState extends StatelessWidget {
  const _ReservationActionErrorState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final errorColor =
        Theme.of(context).colorScheme.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorColor,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: errorColor,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}