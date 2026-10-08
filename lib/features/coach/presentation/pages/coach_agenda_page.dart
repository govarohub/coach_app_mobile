import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/pages/reservation_provider.dart';
import '../../domain/entities/coach_schedule.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo:
/// lib/features/coach/presentation/pages/coach_agenda_page.dart
///
/// CK-017.6 / CK-017.7
///
/// Pantalla "Mi agenda" del Coach.
///
/// Responsabilidades:
/// - Consultar las reservaciones del Coach junto con sus horarios.
/// - Separar próximas sesiones e historial.
/// - Mostrar fecha, hora y estado de cada sesión.
/// - Mostrar loading, error y estado vacío.
/// - Permitir actualizar la agenda.
///
/// IMPORTANTE:
/// - La UI no accede directamente a Firebase.
/// - Se reutilizan los providers existentes de reservaciones y horarios.
/// - No se crea Repository, DataSource ni Provider paralelo.
/// - La administración de disponibilidad continúa en CoachSchedulePage.
/// ---------------------------------------------------------------------------
class CoachAgendaPage extends ConsumerWidget {
  const CoachAgendaPage({
    super.key,
    required this.coachId,
  });

  /// Identificador del Coach cuya agenda se consulta.
  final String coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// -----------------------------------------------------------------------
    /// CK-017.6 / CK-017.7
    ///
    /// Reutilizamos el provider existente de reservaciones del Coach y
    /// asociamos cada reservación con su horario para obtener fecha y hora.
    /// -----------------------------------------------------------------------
    final reservationsAsync = ref.watch(
      coachReservationsWithSchedulesProvider(coachId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi agenda'),
      ),
      body: reservationsAsync.when(
        /// -------------------------------------------------------------------
        /// ESTADO DE CARGA
        /// -------------------------------------------------------------------
        loading: () {
          return const _CoachAgendaLoadingState();
        },

        /// -------------------------------------------------------------------
        /// ESTADO DE ERROR
        /// -------------------------------------------------------------------
        error: (error, stackTrace) {
          return _CoachAgendaErrorState(
            onRetry: () {
              ref.invalidate(
                coachReservationsWithSchedulesProvider(coachId),
              );
            },
          );
        },

        /// -------------------------------------------------------------------
        /// ESTADO DE DATOS
        /// -------------------------------------------------------------------
        data: (items) {
          final now = DateTime.now();

          /// Próximas sesiones: pendientes o confirmadas cuya fecha/hora
          /// todavía no ha transcurrido.
          final upcoming = items
              .where(
                (item) => _isUpcoming(
              item.reservation,
              item.schedule,
              now,
            ),
          )
              .toList()
            ..sort(_compareUpcoming);

          /// Historial: sesiones pasadas o reservaciones completadas/canceladas.
          final history = items
              .where(
                (item) => !_isUpcoming(
              item.reservation,
              item.schedule,
              now,
            ),
          )
              .toList()
            ..sort(_compareHistory);

          /// ---------------------------------------------------------------
          /// ESTADO VACÍO
          /// ---------------------------------------------------------------
          if (items.isEmpty) {
            return _CoachAgendaEmptyState(
              onRefresh: () async {
                ref.invalidate(
                  coachReservationsWithSchedulesProvider(coachId),
                );

                await ref.read(
                  coachReservationsWithSchedulesProvider(coachId).future,
                );
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                coachReservationsWithSchedulesProvider(coachId),
              );

              await ref.read(
                coachReservationsWithSchedulesProvider(coachId).future,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  const _AgendaSectionTitle(
                    title: 'Próximas sesiones',
                  ),
                  const SizedBox(height: 12),
                  ...upcoming.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CoachAgendaCard(
                        reservation: item.reservation,
                        schedule: item.schedule,
                      ),
                    ),
                  ),
                ],
                if (history.isNotEmpty) ...[
                  if (upcoming.isNotEmpty)
                    const SizedBox(height: 12),
                  const _AgendaSectionTitle(
                    title: 'Historial',
                  ),
                  const SizedBox(height: 12),
                  ...history.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CoachAgendaHistoryCard(
                        reservation: item.reservation,
                        schedule: item.schedule,
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

  /// -------------------------------------------------------------------------
  /// Determina si una reservación pertenece a próximas sesiones.
  /// -------------------------------------------------------------------------
  bool _isUpcoming(
      Reservation reservation,
      CoachSchedule schedule,
      DateTime now,
      ) {
    /// Una reservación completada o cancelada pertenece al historial,
    /// independientemente de la fecha del horario.
    if (reservation.status == 'completed' ||
        reservation.status == 'cancelled') {
      return false;
    }

    return _scheduleDateTime(schedule).isAfter(now);
  }

  /// -------------------------------------------------------------------------
  /// Orden cronológico ascendente para próximas sesiones.
  /// -------------------------------------------------------------------------
  int _compareUpcoming(
      ({Reservation reservation, CoachSchedule schedule}) first,
      ({Reservation reservation, CoachSchedule schedule}) second,
      ) {
    return _scheduleDateTime(first.schedule).compareTo(
      _scheduleDateTime(second.schedule),
    );
  }

  /// -------------------------------------------------------------------------
  /// Orden cronológico descendente para historial.
  /// -------------------------------------------------------------------------
  int _compareHistory(
      ({Reservation reservation, CoachSchedule schedule}) first,
      ({Reservation reservation, CoachSchedule schedule}) second,
      ) {
    return _scheduleDateTime(second.schedule).compareTo(
      _scheduleDateTime(first.schedule),
    );
  }

  /// -------------------------------------------------------------------------
  /// Obtiene la fecha y hora real de una sesión.
  /// -------------------------------------------------------------------------
  DateTime _scheduleDateTime(CoachSchedule schedule) {
    final parts = schedule.startTime.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return DateTime(
      schedule.date.year,
      schedule.date.month,
      schedule.date.day,
      hour,
      minute,
    );
  }
}

/// ---------------------------------------------------------------------------
/// Título de sección.
/// ---------------------------------------------------------------------------
class _AgendaSectionTitle extends StatelessWidget {
  const _AgendaSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

/// ---------------------------------------------------------------------------
/// Tarjeta de una próxima sesión.
/// ---------------------------------------------------------------------------
class _CoachAgendaCard extends StatelessWidget {
  const _CoachAgendaCard({
    required this.reservation,
    required this.schedule,
  });

  final Reservation reservation;
  final CoachSchedule schedule;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: const CircleAvatar(
          child: Icon(Icons.event_available_outlined),
        ),
        title: Text(
          _formatDate(schedule.date),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${schedule.startTime} - ${schedule.endTime}',
          ),
        ),
        trailing: _ReservationStatusLabel(
          status: reservation.status,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

/// ---------------------------------------------------------------------------
/// Tarjeta de una sesión del historial.
/// ---------------------------------------------------------------------------
class _CoachAgendaHistoryCard extends StatelessWidget {
  const _CoachAgendaHistoryCard({
    required this.reservation,
    required this.schedule,
  });

  final Reservation reservation;
  final CoachSchedule schedule;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: const CircleAvatar(
          child: Icon(Icons.history),
        ),
        title: Text(
          _formatDate(schedule.date),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${schedule.startTime} - ${schedule.endTime}',
          ),
        ),
        trailing: _ReservationStatusLabel(
          status: reservation.status,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

/// ---------------------------------------------------------------------------
/// Estado visual de la reservación.
/// ---------------------------------------------------------------------------
class _ReservationStatusLabel extends StatelessWidget {
  const _ReservationStatusLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _statusIcon(status),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          _statusLabel(status),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _statusIcon(String value) {
    switch (value) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'confirmed':
        return Icons.event_available_outlined;
      case 'pending':
        return Icons.pending_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      case 'confirmed':
        return 'Confirmada';
      case 'pending':
        return 'Pendiente';
      default:
        return value;
    }
  }
}

/// ---------------------------------------------------------------------------
/// Estado de carga.
/// ---------------------------------------------------------------------------
class _CoachAgendaLoadingState extends StatelessWidget {
  const _CoachAgendaLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Estado vacío.
/// ---------------------------------------------------------------------------
class _CoachAgendaEmptyState extends StatelessWidget {
  const _CoachAgendaEmptyState({
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Icon(
            Icons.event_note_outlined,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No tienes sesiones programadas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Las sesiones reservadas aparecerán aquí.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Estado de error.
/// ---------------------------------------------------------------------------
class _CoachAgendaErrorState extends StatelessWidget {
  const _CoachAgendaErrorState({
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
            const Text(
              'No fue posible cargar la agenda.',
              textAlign: TextAlign.center,
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
