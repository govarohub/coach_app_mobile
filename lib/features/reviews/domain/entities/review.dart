/// Represents a client's review of a completed reservation.
///
/// CK-019.3
///
/// This domain entity has no Firebase or presentation dependencies.
class Review {
  const Review({
    required this.reservationId,
    required this.coachId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Reservation ID and Firestore document ID for this review.
  final String reservationId;

  /// UID of the coach reviewed by the client.
  final String coachId;

  /// Whole-number rating from 1 to 5.
  final int rating;

  /// Optional client comment.
  final String? comment;

  /// Timestamp when this review was first created.
  final DateTime createdAt;

  /// Timestamp of the most recent create or edit operation.
  final DateTime updatedAt;
}
