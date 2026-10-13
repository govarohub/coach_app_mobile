import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../coach/domain/entities/coach_schedule.dart';
import '../../../coach/presentation/pages/coach_profile_provider.dart';
import 'reservation_provider.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/services/reservation_business_rules.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo:
/// lib/features/reservation/presentation/pages/reservations_page.dart
///
/// CK-017.7
///
/// Pantalla "Mis reservaciones".
///
/// Responsabilidades:
/// - Consultar las reservaciones del cliente autenticado.
/// - Separar próximas sesiones e historial.
/// - Utilizar la fecha y hora real del horario asociado.
/// - Mostrar loading, error, vacío y reintento.
/// - Mantener la consulta dentro de los providers existentes del módulo.
///
/// IMPORTANTE:
/// - No accede directamente a Firebase.
/// - No crea Repository ni DataSource paralelo.
/// ---------------------------------------------------------------------------
class ReservationsPage extends ConsumerWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// -----------------------------------------------------------------------
    /// CK-017.7
    ///
    /// El provider combina cada reservación con su horario para conocer la
    /// fecha y hora real de la sesión.
    /// -----------------------------------------------------------------------
    final reservationsAsync = ref.watch(
      clientReservationsWithSchedulesProvider,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Regresar',
          onPressed: () => context.pop(),
        ),
        title: const Text('Mis reservaciones'),
      ),
      body: reservationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) {
          return _ReservationsErrorState(
            onRetry: () {
              ref.invalidate(clientReservationsWithSchedulesProvider);
            },
          );
        },
        data: (items) {
          final uniqueItems = <({Reservation reservation, CoachSchedule schedule})>[];
          final seenScheduleIds = <String>{};

          for (final item in items) {
            final key = item.schedule.scheduleId;
            if (seenScheduleIds.add(key)) {
              uniqueItems.add(item);
            }
          }

          if (uniqueItems.isEmpty) {
            return const _ReservationsEmptyState();
          }

          final now = DateTime.now();
          final upcoming = uniqueItems
              .where((item) => _isUpcoming(item.reservation, item.schedule, now))
              .toList()
            ..sort(_compareUpcoming);

          final history = uniqueItems
              .where((item) => !_isUpcoming(item.reservation, item.schedule, now))
              .toList()
            ..sort(_compareHistory);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(clientReservationsWithSchedulesProvider);
              await ref.read(
                clientReservationsWithSchedulesProvider.future,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  const _SectionTitle(title: 'Próximas sesiones'),
                  const SizedBox(height: 12),
                  ...upcoming.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReservationCard(
                        reservation: item.reservation,
                        schedule: item.schedule,
                      ),
                    ),
                  ),
                ],
                if (history.isNotEmpty) ...[
                  if (upcoming.isNotEmpty) const SizedBox(height: 12),
                  const _SectionTitle(title: 'Historial'),
                  const SizedBox(height: 12),
                  ...history.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReservationCard(
                        reservation: item.reservation,
                        schedule: item.schedule,
                        history: true,
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
  /// Determina si la reservación pertenece a próximas sesiones.
  ///
  /// Las reservaciones completadas o canceladas siempre pertenecen al
  /// historial, aunque la fecha del horario todavía no haya transcurrido.
  /// -------------------------------------------------------------------------
  bool _isUpcoming(
      Reservation reservation,
      CoachSchedule schedule,
      DateTime now,
      ) {
    if (reservation.status == 'completed' ||
        reservation.status == 'cancelled') {
      return false;
    }

    return _scheduleDateTime(schedule).isAfter(now);
  }

  int _compareUpcoming(
      ({Reservation reservation, CoachSchedule schedule}) first,
      ({Reservation reservation, CoachSchedule schedule}) second,
      ) {
    return _scheduleDateTime(first.schedule).compareTo(
      _scheduleDateTime(second.schedule),
    );
  }

  int _compareHistory(
      ({Reservation reservation, CoachSchedule schedule}) first,
      ({Reservation reservation, CoachSchedule schedule}) second,
      ) {
    return _scheduleDateTime(second.schedule).compareTo(
      _scheduleDateTime(first.schedule),
    );
  }

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
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

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
/// Tarjeta de reservación.
/// ---------------------------------------------------------------------------
class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.schedule,
    this.history = false,
  });

  final Reservation reservation;
  final CoachSchedule schedule;
  final bool history;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  history ? Icons.history : Icons.event_available,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDate(schedule.date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _ReservationStatusChip(status: reservation.status),
              ],
            ),
            const SizedBox(height: 12),
            _ReservationInfoRow(
              label: 'Horario',
              value: Text(
                ReservationBusinessRules.formatTimeRange(
                  schedule.startTime,
                  schedule.endTime,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ReservationInfoRow(
              label: 'Coach',
              value: _CoachName(coachId: reservation.coachId),
            ),
            const SizedBox(height: 8),
            _ReservationInfoRow(
              label: 'Monto',
              value: Text('\$${reservation.amount.toStringAsFixed(2)}'),
            ),
          ],
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

class _CoachName extends ConsumerWidget {
  const _CoachName({required this.coachId});

  final String coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(coachPublicIdentityProvider(coachId));

    return identityAsync.when(
      data: (identity) => Text(identity.name),
      loading: () => const Text('Cargando...'),
      error: (_, _) => const Text('No disponible'),
    );
  }
}

class _ReservationInfoRow extends StatelessWidget {
  const _ReservationInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: value),
      ],
    );
  }
}

class _ReservationStatusChip extends StatelessWidget {
  const _ReservationStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(_statusLabel(status)));
  }

  String _statusLabel(String value) {
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
            Icon(Icons.event_busy_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'No tienes reservaciones.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
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

class _ReservationsErrorState extends StatelessWidget {
  const _ReservationsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 16),
            const Text(
              'No fue posible cargar tus reservaciones.',
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
