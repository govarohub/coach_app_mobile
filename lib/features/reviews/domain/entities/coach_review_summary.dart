import 'review.dart';

/// Aggregated rating information derived from canonical review documents.
class CoachReviewSummary {
  const CoachReviewSummary({
    required this.reviewCount,
    required this.averageRating,
  });

  final int reviewCount;
  final double? averageRating;

  factory CoachReviewSummary.fromReviews(Iterable<Review> reviews) {
    var totalRating = 0;
    var reviewCount = 0;

    for (final review in reviews) {
      totalRating += review.rating;
      reviewCount++;
    }

    if (reviewCount == 0) {
      return const CoachReviewSummary(
        reviewCount: 0,
        averageRating: null,
      );
    }

    return CoachReviewSummary(
      reviewCount: reviewCount,
      averageRating: totalRating / reviewCount,
    );
  }
}