import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/coach/domain/entities/coach_schedule.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_agenda_page.dart';
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