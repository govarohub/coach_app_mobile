import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/coach/domain/entities/coach_profile.dart';
import 'package:coach_app_mobile/features/coach/domain/entities/coach_schedule.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_profile_provider.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_schedule_provider.dart';
import 'package:coach_app_mobile/features/reservation/presentation/pages/reservation_page.dart';

void main() {
  testWidgets('orders available sessions by date and start time', (
    tester,
  ) async {
    final schedules = [
      _schedule(day: 14, startTime: '08:00', endTime: '09:00'),
      _schedule(day: 13, startTime: '11:00', endTime: '12:00'),
      _schedule(day: 13, startTime: '09:00', endTime: '10:00'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coachAvailableSchedulesProvider.overrideWith(
            (ref, coachId) async => schedules,
          ),
          coachProfileProvider.overrideWith(
            (ref, coachId) async => const CoachProfile(
              coachId: 'coach-1',
              specialties: [],
              experienceYears: 5,
              hourlyRate: 250,
              rating: 5,
              verified: true,
              available: true,
            ),
          ),
        ],
        child: const MaterialApp(home: ReservationPage(coachId: 'coach-1')),
      ),
    );
    await tester.pumpAndSettle();

    final displayedTimes = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => tile.subtitle)
        .whereType<Text>()
        .map((subtitle) => subtitle.data)
        .toList();

    expect(displayedTimes, ['09:00 - 10:00', '11:00 - 12:00', '08:00 - 09:00']);
  });
}

CoachSchedule _schedule({
  required int day,
  required String startTime,
  required String endTime,
}) {
  return CoachSchedule(
    scheduleId: '$day-$startTime',
    coachId: 'coach-1',
    date: DateTime(2026, 11, day),
    startTime: startTime,
    endTime: endTime,
    status: 'available',
  );
}
