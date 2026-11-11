import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/coach/domain/entities/coach_schedule.dart';
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
