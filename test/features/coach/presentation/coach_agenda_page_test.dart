import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/coach/domain/entities/coach_schedule.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_agenda_page.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_schedule_provider.dart';
import 'package:coach_app_mobile/features/reservation/domain/entities/reservation.dart';
import 'package:coach_app_mobile/features/reservation/presentation/pages/reservation_provider.dart';

void main() {
  testWidgets('shows coach completion verification for a pending history item', (
    tester,
  ) async {
    final controller = _FakeReservationController();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    await tester.pumpWidget(
      _testApp(
        scheduleDate: yesterday,
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marcar sesión como completada'), findsOneWidget);

    await tester.tap(find.text('Marcar sesión como completada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(controller.completedReservationId, 'reservation-1');
  });

  testWidgets('does not show completion action for an upcoming session', (
    tester,
  ) async {
    final controller = _FakeReservationController();

    await tester.pumpWidget(
      _testApp(
        scheduleDate: DateTime.now().add(const Duration(days: 1)),
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marcar sesión como completada'), findsNothing);
  });

  testWidgets('shows only reserved schedules in the coach agenda', (
    tester,
  ) async {
    final reservedDate = DateTime.now().add(const Duration(days: 2));
    final availableDate = DateTime.now().add(const Duration(days: 3));
    final reservedSchedule = CoachSchedule(
      scheduleId: 'schedule-reserved',
      coachId: 'coach-1',
      date: reservedDate,
      startTime: '08:00',
      endTime: '10:00',
      status: 'reserved',
    );
    final availableSchedule = CoachSchedule(
      scheduleId: 'schedule-available',
      coachId: 'coach-1',
      date: availableDate,
      startTime: '08:00',
      endTime: '10:00',
      status: 'available',
    );
    final reservation = Reservation(
      reservationId: 'reservation-1',
      clientId: 'client-1',
      coachId: 'coach-1',
      scheduleId: reservedSchedule.scheduleId,
      status: 'pending',
      amount: 250,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coachSchedulesProvider.overrideWith(
            (ref, coachId) async => [reservedSchedule, availableSchedule],
          ),
          coachReservationsProvider.overrideWith(
            (ref, coachId) async => [reservation],
          ),
        ],
        child: const MaterialApp(
          home: CoachAgendaPage(coachId: 'coach-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_formatDate(reservedDate)), findsOneWidget);
    expect(find.text(_formatDate(availableDate)), findsNothing);
  });
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

Widget _testApp({
  required DateTime scheduleDate,
  required _FakeReservationController controller,
}) {
  final reservation = Reservation(
    reservationId: 'reservation-1',
    clientId: 'client-1',
    coachId: 'coach-1',
    scheduleId: 'schedule-1',
    status: 'pending',
    amount: 200,
    createdAt: DateTime(2026, 10, 1),
  );
  final schedule = CoachSchedule(
    scheduleId: 'schedule-1',
    coachId: 'coach-1',
    date: scheduleDate,
    startTime: '08:00',
    endTime: '09:00',
    status: 'reserved',
  );

  return ProviderScope(
    overrides: [
      coachAgendaItemsProvider.overrideWith(
        (ref, coachId) async => [
          (reservation: reservation, schedule: schedule),
        ],
      ),
      reservationControllerProvider.overrideWith(() => controller),
    ],
    child: const MaterialApp(
      home: CoachAgendaPage(coachId: 'coach-1'),
    ),
  );
}

class _FakeReservationController extends ReservationController {
  String? completedReservationId;

  @override
  Future<void> build() async {}

  @override
  Future<void> completeReservationAsCoach({
    required String reservationId,
  }) async {
    completedReservationId = reservationId;
  }
}