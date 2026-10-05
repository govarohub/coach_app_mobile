import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'reservation_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo:
/// lib/features/reservation/presentation/pages/reservations_page.dart
///
/// CK-016.11
///
/// Pantalla "Mis reservaciones".
///
/// Responsabilidades:
/// - Consultar las reservaciones del cliente autenticado.
/// - Mostrar estado de carga.
/// - Mostrar estado de error.
/// - Mostrar estado vacío.
/// - Mostrar las reservaciones existentes.
///
/// IMPORTANTE:
/// - La pantalla no accede directamente a Firestore.
/// - Utiliza el provider existente del módulo de reservaciones.
/// - No se crea un DataSource ni Repository paralelo.
/// ---------------------------------------------------------------------------
class ReservationsPage extends ConsumerWidget {
  const ReservationsPage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    /// -----------------------------------------------------------------------
    /// Consulta las reservaciones del cliente autenticado.
    ///
    /// El provider existente obtiene el usuario autenticado y consulta
    /// únicamente sus reservaciones.
    /// -----------------------------------------------------------------------
    final reservationsAsync = ref.watch(
      clientReservationsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        // Regresa a la pantalla anterior mediante GoRouter.
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          tooltip: 'Regresar',
          onPressed: () {
            context.pop();
          },
        ),

        title: const Text(
          'Mis reservaciones',
        ),
      ),
      body: reservationsAsync.when(
        /// -------------------------------------------------------------------
        /// Estado de carga.
        /// -------------------------------------------------------------------
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },

        /// -------------------------------------------------------------------
        /// Estado de error.
        /// -------------------------------------------------------------------
        error: (error, stackTrace) {
          return _ReservationsErrorState(
            onRetry: () {
              /// Reintenta la consulta utilizando el provider existente.
              ref.invalidate(
                clientReservationsProvider,
              );
            },
          );
        },

        /// -------------------------------------------------------------------
        /// Datos obtenidos correctamente.
        /// -------------------------------------------------------------------
        data: (reservations) {
          /// ---------------------------------------------------------------
          /// Estado vacío.
          /// ---------------------------------------------------------------
          if (reservations.isEmpty) {
            return const _ReservationsEmptyState();
          }

          /// ---------------------------------------------------------------
          /// Lista de reservaciones.
          /// ---------------------------------------------------------------
          return RefreshIndicator(
            onRefresh: () async {
              /// Actualiza la información de reservaciones.
              ref.invalidate(
                clientReservationsProvider,
              );

              /// Espera a que termine la nueva consulta.
              await ref.read(
                clientReservationsProvider.future,
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reservations.length,
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
                final reservation = reservations[index];

                return _ReservationCard(
                  reservationId: reservation.reservationId,
                  coachId: reservation.coachId,
                  scheduleId: reservation.scheduleId,
                  status: reservation.status,
                  amount: reservation.amount,
                  createdAt: reservation.createdAt,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Tarjeta de una reservación.
///
/// Esta primera integración muestra únicamente información que ya pertenece
/// a la entidad Reservation.
///
/// No se consulta Firebase adicionalmente para obtener información del Coach
/// o del horario.
/// ---------------------------------------------------------------------------
class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservationId,
    required this.coachId,
    required this.scheduleId,
    required this.status,
    required this.amount,
    required this.createdAt,
  });

  final String reservationId;
  final String coachId;
  final String scheduleId;
  final String status;
  final double amount;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---------------------------------------------------------------
            /// Encabezado.
            /// ---------------------------------------------------------------
            Row(
              children: [
                const Icon(
                  Icons.event_available,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Text(
                    'Reservación',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
                _ReservationStatusChip(
                  status: status,
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            /// ---------------------------------------------------------------
            /// Identificador de reservación.
            /// ---------------------------------------------------------------
            _ReservationInfoRow(
              label: 'Reservación',
              value: reservationId,
            ),

            const SizedBox(
              height: 8,
            ),

            /// ---------------------------------------------------------------
            /// Coach.
            /// ---------------------------------------------------------------
            _ReservationInfoRow(
              label: 'Coach',
              value: coachId,
            ),

            const SizedBox(
              height: 8,
            ),

            /// ---------------------------------------------------------------
            /// Horario.
            /// ---------------------------------------------------------------
            _ReservationInfoRow(
              label: 'Horario',
              value: scheduleId,
            ),

            const SizedBox(
              height: 8,
            ),

            /// ---------------------------------------------------------------
            /// Monto.
            /// ---------------------------------------------------------------
            _ReservationInfoRow(
              label: 'Monto',
              value: '\$${amount.toStringAsFixed(2)}',
            ),

            const SizedBox(
              height: 8,
            ),

            /// ---------------------------------------------------------------
            /// Fecha de creación.
            /// ---------------------------------------------------------------
            _ReservationInfoRow(
              label: 'Creada',
              value: _formatDate(createdAt),
            ),
          ],
        ),
      ),
    );
  }

  /// Formato visual de la fecha de creación.
  String _formatDate(
      DateTime date,
      ) {
    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    final hour = date.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = date.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year} $hour:$minute';
  }
}

/// ---------------------------------------------------------------------------
/// Fila de información de una reservación.
/// ---------------------------------------------------------------------------
class _ReservationInfoRow extends StatelessWidget {
  const _ReservationInfoRow({
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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Estado del status de la reservación.
/// ---------------------------------------------------------------------------
class _ReservationStatusChip extends StatelessWidget {
  const _ReservationStatusChip({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        _statusLabel(status),
      ),
    );
  }

  /// Traduce únicamente los estados oficiales de Reservation.
  String _statusLabel(
      String value,
      ) {
    switch (value) {
      case 'pending':
        return 'Pendiente';

      case 'confirmed':
        return 'Confirmada';

      case 'completed':
        return 'Completada';

      case 'cancelled':
        return 'Cancelada';

      default:
        return value;
    }
  }
}

/// ---------------------------------------------------------------------------
/// Estado vacío.
/// ---------------------------------------------------------------------------
class _ReservationsEmptyState extends StatelessWidget {
  const _ReservationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
            ),
            SizedBox(
              height: 16,
            ),
            Text(
              'No tienes reservaciones.',
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              'Cuando reserves una sesión aparecerá aquí.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Estado de error.
/// ---------------------------------------------------------------------------
class _ReservationsErrorState extends StatelessWidget {
  const _ReservationsErrorState({
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
              size: 56,
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'No fue posible cargar tus reservaciones.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton(
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