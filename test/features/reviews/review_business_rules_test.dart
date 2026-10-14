import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/reviews/domain/entities/review.dart';
import 'package:coach_app_mobile/features/reviews/domain/services/review_business_rules.dart';

void main() {
  group('ReviewBusinessRules', () {
    test('accepts integer ratings from one through five', () {
      for (var rating = 1; rating <= 5; rating++) {
        expect(
          () => ReviewBusinessRules.validateRating(rating),
          returnsNormally,
        );
      }
    });

    test('rejects out-of-range and fractional ratings', () {
      for (final rating in <num>[0, 6, 2.5]) {
        expect(
          () => ReviewBusinessRules.validateRating(rating),
          throwsArgumentError,
        );
      }
    });

    test('trims comments and treats empty comments as absent', () {
      expect(
        ReviewBusinessRules.normalizeComment('  Muy buena  '),
        'Muy buena',
      );
      expect(ReviewBusinessRules.normalizeComment('   '), isNull);
      expect(ReviewBusinessRules.normalizeComment(null), isNull);
    });

    test('rejects comments longer than 500 characters', () {
      expect(
        () => ReviewBusinessRules.normalizeComment('a' * 501),
        throwsArgumentError,
      );
    });

    test('validates required review identifiers and content', () {
      final timestamp = DateTime(2026, 10, 13);
      final review = Review(
        reservationId: 'reservation-1',
        coachId: 'coach-1',
        rating: 5,
        comment: 'Buena sesión',
        createdAt: timestamp,
        updatedAt: timestamp,
      );

      expect(() => ReviewBusinessRules.validateReview(review), returnsNormally);

      expect(
        () => ReviewBusinessRules.validateReview(
          Review(
            reservationId: 'reservation-1',
            coachId: ' ',
            rating: 5,
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('allows only the owner of a completed reservation to review', () {
      expect(
        () => ReviewBusinessRules.validateReviewEligibility(
          reservationStatus: 'completed',
          reservationClientId: 'client-1',
          reservationCoachId: 'coach-1',
          authenticatedClientId: 'client-1',
        ),
        returnsNormally,
      );

      expect(
        () => ReviewBusinessRules.validateReviewEligibility(
          reservationStatus: 'confirmed',
          reservationClientId: 'client-1',
          reservationCoachId: 'coach-1',
          authenticatedClientId: 'client-1',
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        () => ReviewBusinessRules.validateReviewEligibility(
          reservationStatus: 'completed',
          reservationClientId: 'client-1',
          reservationCoachId: 'coach-1',
          authenticatedClientId: 'client-2',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects self-reviews', () {
      expect(
        () => ReviewBusinessRules.validateReviewEligibility(
          reservationStatus: 'completed',
          reservationClientId: 'same-user',
          reservationCoachId: 'same-user',
          authenticatedClientId: 'same-user',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('prevents changing review reservation or coach when editing', () {
      final createdAt = DateTime(2026, 10, 13);
      final review = Review(
        reservationId: 'reservation-1',
        coachId: 'coach-1',
        rating: 5,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      expect(
        () => ReviewBusinessRules.validateReviewUpdate(
          existingReview: review,
          reservationId: 'reservation-1',
          reservationClientId: 'client-1',
          coachId: 'coach-1',
          createdAt: createdAt,
          authenticatedClientId: 'client-1',
          rating: 4,
          comment: 'Actualizada',
        ),
        returnsNormally,
      );

      expect(
        () => ReviewBusinessRules.validateReviewUpdate(
          existingReview: review,
          reservationId: 'reservation-2',
          reservationClientId: 'client-1',
          coachId: 'coach-1',
          createdAt: createdAt,
          authenticatedClientId: 'client-1',
          rating: 4,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects updatedAt earlier than createdAt', () {
      expect(
        () => ReviewBusinessRules.validateTimestamps(
          createdAt: DateTime(2026, 10, 13, 12),
          updatedAt: DateTime(2026, 10, 13, 11),
        ),
        throwsArgumentError,
      );
    });
  });
}
