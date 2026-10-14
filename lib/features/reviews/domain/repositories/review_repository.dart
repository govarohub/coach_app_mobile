import '../entities/review.dart';

/// Domain contract for persisted coach reviews.
///
/// CK-019.4
abstract interface class ReviewRepository {
  Future<Review?> getReview(String reservationId);

  Future<List<Review>> getReviewsByCoach(String coachId);

  Future<void> createReview({
    required String reservationId,
    required String coachId,
    required int rating,
    String? comment,
  });

  Future<void> updateReview({
    required String reservationId,
    required int rating,
    String? comment,
  });
}
