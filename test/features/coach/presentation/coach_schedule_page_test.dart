import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/coach/domain/entities/coach_schedule.dart';
import 'package:coach_app_mobile/features/coach/domain/repositories/coach_schedule_repository.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_schedule_page.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_schedule_provider.dart';

void main() {
  testWidgets('hides reserved schedules from coach availability', (
    tester,
  ) async {
    final schedules = [
      _schedule(id: 'available', day: 13, status: 'available'),
      _schedule(id: 'blocked', day: 14, status: 'blocked'),
      _schedule(id: 'reserved', day: 15, status: 'reserved'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coachSchedulesProvider.overrideWith(
            (ref, coachId) async => schedules,
          ),
        ],
        child: const MaterialApp(home: CoachSchedulePage(coachId: 'coach-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('13/11/2026'), findsOneWidget);
    expect(find.text('14/11/2026'), findsOneWidget);
    expect(find.text('15/11/2026'), findsNothing);
  });

  testWidgets('opens the schedule calendar in Spanish', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coachSchedulesProvider.overrideWith(
            (ref, coachId) async => [],
          ),
        ],
        child: const MaterialApp(home: CoachSchedulePage(coachId: 'coach-1')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo horario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fecha'));
    await tester.pumpAndSettle();

    final dialog = find.byType(DatePickerDialog);
    final context = tester.element(dialog);
    final localizations = MaterialLocalizations.of(context);
    expect(Localizations.localeOf(context).languageCode, 'es');
    expect(find.text('Seleccionar fecha'), findsOneWidget);
    expect(find.text(localizations.formatMonthYear(DateTime.now())), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('ACEPTAR'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Select date'), findsNothing);

    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
  });

  testWidgets('edits availability and keeps blocked schedules editable', (
    tester,
  ) async {
    final repository = _ScheduleRepository(
      _schedule(id: 'schedule', day: 13, status: 'available'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coachScheduleRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: CoachSchedulePage(coachId: 'coach-1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar horario'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No disponible').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(repository.schedule.status, 'blocked');
    expect(repository.schedule.startTime, '08:00');
    expect(find.text('Bloqueado'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar horario'));
    await tester.pumpAndSettle();
    expect(find.text('No disponible'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disponible').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(repository.schedule.status, 'available');
  });

  testWidgets('preserves legacy AM and PM times while changing status', (
    tester,
  ) async {
    final repository = _ScheduleRepository(
      CoachSchedule(
        scheduleId: 'schedule',
        coachId: 'coach-1',
        date: DateTime(2026, 11, 13),
        startTime: '12:00 PM',
        endTime: '2:00 PM',
        status: 'available',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [coachScheduleRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: CoachSchedulePage(coachId: 'coach-1')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar horario'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No disponible').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(repository.schedule.status, 'blocked');
    expect(repository.schedule.startTime, '12:00');
    expect(repository.schedule.endTime, '14:00');
  });
}

class _ScheduleRepository implements CoachScheduleRepository {
  _ScheduleRepository(this.schedule);

  CoachSchedule schedule;

  @override
  Future<List<CoachSchedule>> getSchedules(String coachId) async => [schedule];

  @override
  Future<List<CoachSchedule>> getAvailableSchedules(String coachId) async =>
      schedule.status == 'available' ? [schedule] : [];

  @override
  Future<void> updateSchedule({
    required String scheduleId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String status,
  }) async {
    schedule = CoachSchedule(
      scheduleId: scheduleId,
      coachId: schedule.coachId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: status,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CoachSchedule _schedule({
  required String id,
  required int day,
  required String status,
}) {
  return CoachSchedule(
    scheduleId: id,
    coachId: 'coach-1',
    date: DateTime(2026, 11, day),
    startTime: '08:00',
    endTime: '10:00',
    status: status,
  );
}
