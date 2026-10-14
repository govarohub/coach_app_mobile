import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/reservation/domain/entities/reservation.dart';
import 'package:coach_app_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:coach_app_mobile/features/reviews/domain/entities/review.dart';
import 'package:coach_app_mobile/features/reviews/domain/repositories/review_repository.dart';
import 'package:coach_app_mobile/features/reviews/domain/services/review_service.dart';

void main() {
  group('ReviewService', () {
    test('creates a review for the owner of a completed reservation', () async {
      final reviewRepository = _FakeReviewRepository();
      final service = _createService(
        reservationStatus: 'completed',
        reviewRepository: reviewRepository,
      );

      final eligibility = await service.submitReview(
        reservationId: 'reservation-1',
        authenticatedClientId: 'client-1',
        rating: 5,
        comment: '  Muy buena sesión  ',
      );

      expect(eligibility.reservation.reservationId, 'reservation-1');
      expect(reviewRepository.createdReview?.reservationId, 'reservation-1');
      expect(reviewRepository.createdReview?.coachId, 'coach-1');
      expect(reviewRepository.createdReview?.comment, 'Muy buena sesión');
      expect(reviewRepository.updatedRating, isNull);
    });

    test('rejects reservations that are not completed', () async {
      final reviewRepository = _FakeReviewRepository();
      final service = _createService(
        reservationStatus: 'confirmed',
        reviewRepository: reviewRepository,
      );

      await expectLater(
        service.submitReview(
          reservationId: 'reservation-1',
          authenticatedClientId: 'client-1',
          rating: 4,
        ),
        throwsA(isA<StateError>()),
      );
      expect(reviewRepository.createdReview, isNull);
    });

    test('rejects clients who do not own the reservation', () async {
      final reviewRepository = _FakeReviewRepository();
      final service = _createService(
        reservationStatus: 'completed',
        reviewRepository: reviewRepository,
      );

      await expectLater(
        service.checkEligibility(
          reservationId: 'reservation-1',
          authenticatedClientId: 'client-2',
        ),
        throwsA(isA<StateError>()),
      );
      expect(reviewRepository.getReviewCalls, 0);
    });

    test(
      'edits an existing review owned by the authenticated client',
      () async {
        final reviewRepository = _FakeReviewRepository(
          existingReview: _review(),
        );
        final service = _createService(
          reservationStatus: 'completed',
          reviewRepository: reviewRepository,
        );

        final eligibility = await service.submitReview(
          reservationId: 'reservation-1',
          authenticatedClientId: 'client-1',
          rating: 3,
          comment: 'Actualizada',
        );

        expect(eligibility.existingReview?.rating, 5);
        expect(reviewRepository.updatedRating, 3);
        expect(reviewRepository.updatedComment, 'Actualizada');
        expect(reviewRepository.createdReview, isNull);
      },
    );

    test('rejects an existing review associated with another coach', () async {
      final reviewRepository = _FakeReviewRepository(
        existingReview: _review(coachId: 'coach-2'),
      );
      final service = _createService(
        reservationStatus: 'completed',
        reviewRepository: reviewRepository,
      );

      await expectLater(
        service.checkEligibility(
          reservationId: 'reservation-1',
          authenticatedClientId: 'client-1',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

ReviewService _createService({
  required String reservationStatus,
  required _FakeReviewRepository reviewRepository,
}) {
  return ReviewService(
    _FakeReservationRepository(reservationStatus),
    reviewRepository,
  );
}

Review _review({String coachId = 'coach-1'}) {
  final createdAt = DateTime(2026, 10, 13);
  return Review(
    reservationId: 'reservation-1',
    coachId: coachId,
    rating: 5,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

class _FakeReservationRepository implements ReservationRepository {
  _FakeReservationRepository(String status)
    : reservation = Reservation(
        reservationId: 'reservation-1',
        clientId: 'client-1',
        coachId: 'coach-1',
        scheduleId: 'schedule-1',
        status: status,
        amount: 100,
        createdAt: DateTime(2026, 10, 1),
      );

  final Reservation reservation;

  @override
  Future<Reservation> getReservation(String reservationId) async => reservation;

  @override
  Future<List<Reservation>> getClientReservations(String clientId) async =>
      throw UnimplementedError();

  @override
  Future<List<Reservation>> getCoachReservations(String coachId) async =>
      throw UnimplementedError();

  @override
  Future<String> createReservation({
    required String clientId,
    required String coachId,
    required String scheduleId,
    String? paymentId,
    required String status,
    required double amount,
    required DateTime createdAt,
  }) async => throw UnimplementedError();

  @override
  Future<bool> hasActiveReservationForSchedule(String scheduleId) async =>
      throw UnimplementedError();

  @override
  Future<String> createPendingReservation({
    required String clientId,
    required String coachId,
    required String scheduleId,
    required double amount,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateReservationPayment({
    required String reservationId,
    required String paymentId,
  }) async => throw UnimplementedError();
}

class _FakeReviewRepository implements ReviewRepository {
  _FakeReviewRepository({this.existingReview});

  Review? existingReview;
  Review? createdReview;
  int getReviewCalls = 0;
  int? updatedRating;
  String? updatedComment;

  @override
  Future<Review?> getReview(String reservationId) async {
    getReviewCalls++;
    return existingReview;
  }

  @override
  Future<List<Review>> getReviewsByCoach(String coachId) async =>
      throw UnimplementedError();

  @override
  Future<void> createReview({
    required String reservationId,
    required String coachId,
    required int rating,
    String? comment,
  }) async {
    createdReview = Review(
      reservationId: reservationId,
      coachId: coachId,
      rating: rating,
      comment: comment,
      createdAt: DateTime(2026, 10, 13),
      updatedAt: DateTime(2026, 10, 13),
    );
  }

  @override
  Future<void> updateReview({
    required String reservationId,
    required int rating,
    String? comment,
  }) async {
    updatedRating = rating;
    updatedComment = comment;
  }
}
