import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/review.dart';
import '../../domain/services/review_business_rules.dart';

/// Firestore representation of a client review.
///
/// CK-019.4
class ReviewModel extends Review {
  const ReviewModel({
    required super.reservationId,
    required super.clientName,
    required super.coachId,
    required super.rating,
    super.comment,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ReviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
    {String? clientNameFallback,}
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('La reseña ${document.id} no contiene información.');
    }

    final reservationId = data['reservationId'];
    final rawClientName = data['clientName'];
    final coachId = data['coachId'];
    final rating = data['rating'];
    final comment = data['comment'];
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];

    if (reservationId is! String || reservationId != document.id) {
      throw StateError(
        'La reseña ${document.id} no coincide con su reservationId.',
      );
    }
    if (coachId is! String) {
      throw StateError(
        'La reseña ${document.id} no contiene el Coach asociado.',
      );
    }
    if (rawClientName != null && rawClientName is! String) {
      throw StateError(
        'La reseña ${document.id} contiene un clientName no válido.',
      );
    }
    if (rating is! int) {
      throw StateError(
        'La reseña ${document.id} no contiene un rating entero.',
      );
    }
    if (comment != null && comment is! String) {
      throw StateError(
        'La reseña ${document.id} contiene un comment no válido.',
      );
    }
    if (createdAt is! Timestamp || updatedAt is! Timestamp) {
      throw StateError(
        'La reseña ${document.id} no contiene timestamps válidos.',
      );
    }

    final review = ReviewModel(
      reservationId: reservationId,
      clientName: ReviewBusinessRules.resolveClientName(
        storedName: rawClientName is String ? rawClientName : null,
        profileName: clientNameFallback,
      ),
      coachId: coachId,
      rating: rating,
      comment: comment as String?,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
    );

    ReviewBusinessRules.validateReview(review);
    return review;
  }
}
