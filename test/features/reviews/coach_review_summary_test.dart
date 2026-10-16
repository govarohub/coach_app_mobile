import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/reviews/domain/entities/coach_review_summary.dart';
import 'package:coach_app_mobile/features/reviews/domain/entities/review.dart';

void main() {
  group('CoachReviewSummary', () {
    test('calculates average and count from reviews', () {
      final summary = CoachReviewSummary.fromReviews([
        _review('reservation-1', 5),
        _review('reservation-2', 4),
      ]);

      expect(summary.reviewCount, 2);
      expect(summary.averageRating, 4.5);
    });

    test('does not invent an average when there are no reviews', () {
      final summary = CoachReviewSummary.fromReviews(const []);

      expect(summary.reviewCount, 0);
      expect(summary.averageRating, isNull);
    });
  });
}

Review _review(String reservationId, int rating) {
  final now = DateTime(2026, 10, 13);
  return Review(
    reservationId: reservationId,
    clientName: 'Alberto Valenzo',
    coachId: 'coach-1',
    rating: rating,
    createdAt: now,
    updatedAt: now,
  );
}
