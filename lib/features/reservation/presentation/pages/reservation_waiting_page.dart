import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../coach/domain/entities/coach_schedule.dart';
import '../../../coach/presentation/pages/coach_profile_provider.dart';
import 'reservation_provider.dart';

class ReservationWaitingPage extends ConsumerWidget {
  const ReservationWaitingPage({
    super.key,
    required this.reservationId,
    required this.coachId,
    required this.schedule,
    required this.amount,
  });

  final String reservationId;
  final String coachId;
  final CoachSchedule schedule;
  final double amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(reservationUpdatesProvider(reservationId), (previous, next) {
      final previousStatus = previous?.asData?.value.status;
      final currentStatus = next.asData?.value.status;
      if ((currentStatus != 'confirmed' && currentStatus != 'completed') ||
          previousStatus == 'confirmed' ||
          previousStatus == 'completed') {
        return;
      }

      ref.invalidate(clientReservationsProvider);
      ref.invalidate(clientReservationsWithSchedulesProvider);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Tu solicitud fue aceptada y la sesión quedó agendada.'),
        ),
      );
      context.goNamed(RouteNames.reservations);
    });

    final reservationAsync = ref.watch(
      reservationUpdatesProvider(reservationId),
    );
    final identityAsync = ref.watch(coachPublicIdentityProvider(coachId));

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de reservación')),
      body: reservationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No fue posible consultar el estado de la solicitud.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.invalidate(reservationUpdatesProvider(reservationId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (reservation) {
          if (reservation.status == 'cancelled') {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('La solicitud de reservación fue cancelada.'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 56),
              const SizedBox(height: 16),
              Text(
                'Esperando respuesta del Coach',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Te avisaremos cuando el Coach responda a tu solicitud.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de la solicitud',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _SummaryRow(
                        label: 'Coach',
                        value: identityAsync.when(
                          data: (identity) => identity.name,
                          loading: () => 'Cargando...',
                          error: (error, stackTrace) =>
                              'No fue posible cargar el nombre',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Fecha',
                        value: _formatDate(schedule.date),
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Horario',
                        value: '${schedule.startTime} - ${schedule.endTime}',
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Monto',
                        value: '\$${amount.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Estado',
                        value: reservation.status == 'confirmed'
                            ? 'Confirmada'
                            : 'Pendiente de aceptación',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
