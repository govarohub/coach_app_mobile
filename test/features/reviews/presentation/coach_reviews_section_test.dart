import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/reviews/domain/entities/review.dart';
import 'package:coach_app_mobile/features/reviews/presentation/pages/coach_reviews_section.dart';
import 'package:coach_app_mobile/features/reviews/presentation/review_providers.dart';

void main() {
  testWidgets('shows newest-first reviews without client identity', (
    tester,
  ) async {
    final reviews = [
      _review(
        reservationId: 'reservation-new',
        rating: 5,
        comment: 'Excelente sesión',
        createdAt: DateTime(2026, 10, 13),
      ),
      _review(
        reservationId: 'reservation-old',
        rating: 4,
        comment: 'Muy buena atención',
        createdAt: DateTime(2026, 10, 10),
      ),
    ];

    await tester.pumpWidget(_testApp(reviews));
    await tester.pumpAndSettle();

    expect(find.text('Reseñas'), findsOneWidget);
    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('13/10/2026'), findsOneWidget);
    expect(find.text('Excelente sesión'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('5/5')).dy,
      lessThan(tester.getTopLeft(find.text('4/5')).dy),
    );
  });

  testWidgets('shows an empty state when the coach has no reviews', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const []));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay reseñas.'), findsOneWidget);
  });
}

Widget _testApp(List<Review> reviews) {
  return ProviderScope(
    overrides: [
      coachReviewsProvider.overrideWith((ref, coachId) async => reviews),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CoachReviewsSection(coachId: 'coach-1'),
        ),
      ),
    ),
  );
}

Review _review({
  required String reservationId,
  required int rating,
  required String comment,
  required DateTime createdAt,
}) {
  return Review(
    reservationId: reservationId,
    coachId: 'coach-1',
    rating: rating,
    comment: comment,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
