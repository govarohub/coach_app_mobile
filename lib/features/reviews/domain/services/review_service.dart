import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/domain/repositories/reservation_repository.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';
import 'review_business_rules.dart';

/// Result of checking whether the authenticated client may review a session.
class ReviewEligibility {
  const ReviewEligibility({
    required this.reservation,
    required this.existingReview,
  });

  final Reservation reservation;
  final Review? existingReview;
}

/// Coordinates reservation eligibility with the review repository.
///
/// CK-019.5
class ReviewService {
  ReviewService(this._reservationRepository, this._reviewRepository);

  final ReservationRepository _reservationRepository;
  final ReviewRepository _reviewRepository;

  Future<ReviewEligibility> checkEligibility({
    required String reservationId,
    required String authenticatedClientId,
  }) async {
    final reservation = await _reservationRepository.getReservation(
      reservationId.trim(),
    );
    reservation.validateOfficialStatus();

    ReviewBusinessRules.validateReviewEligibility(
      reservationStatus: reservation.status,
      reservationClientId: reservation.clientId,
      reservationCoachId: reservation.coachId,
      authenticatedClientId: authenticatedClientId,
    );

    final existingReview = await _reviewRepository.getReview(
      reservation.reservationId,
    );

    if (existingReview != null) {
      _validateExistingReview(
        existingReview: existingReview,
        reservation: reservation,
        authenticatedClientId: authenticatedClientId,
      );
    }

    return ReviewEligibility(
      reservation: reservation,
      existingReview: existingReview,
    );
  }

  /// Creates the reservation's only review or edits it if the same client owns it.
  Future<ReviewEligibility> submitReview({
    required String reservationId,
    required String authenticatedClientId,
    required String clientName,
    required int rating,
    String? comment,
  }) async {
    final eligibility = await checkEligibility(
      reservationId: reservationId,
      authenticatedClientId: authenticatedClientId,
    );
    final normalizedClientName = ReviewBusinessRules.normalizeClientName(
      clientName,
    );
    final normalizedComment = ReviewBusinessRules.normalizeComment(comment);

    final existingReview = eligibility.existingReview;
    if (existingReview == null) {
      ReviewBusinessRules.validateReviewContent(
        rating: rating,
        comment: normalizedComment,
      );

      await _reviewRepository.createReview(
        reservationId: eligibility.reservation.reservationId,
        clientName: normalizedClientName,
        coachId: eligibility.reservation.coachId,
        rating: rating,
        comment: normalizedComment,
      );
      return eligibility;
    }

    ReviewBusinessRules.validateReviewUpdate(
      existingReview: existingReview,
      reservationId: eligibility.reservation.reservationId,
      reservationClientId: eligibility.reservation.clientId,
      clientName: normalizedClientName,
      coachId: eligibility.reservation.coachId,
      createdAt: existingReview.createdAt,
      authenticatedClientId: authenticatedClientId,
      rating: rating,
      comment: normalizedComment,
    );

    await _reviewRepository.updateReview(
      reservationId: eligibility.reservation.reservationId,
      clientName: normalizedClientName,
      rating: rating,
      comment: normalizedComment,
    );
    return eligibility;
  }

  void _validateExistingReview({
    required Review existingReview,
    required Reservation reservation,
    required String authenticatedClientId,
  }) {
    ReviewBusinessRules.validateReviewUpdate(
      existingReview: existingReview,
      reservationId: reservation.reservationId,
      reservationClientId: reservation.clientId,
      clientName: existingReview.clientName,
      coachId: reservation.coachId,
      createdAt: existingReview.createdAt,
      authenticatedClientId: authenticatedClientId,
      rating: existingReview.rating,
      comment: existingReview.comment,
    );
  }
}
