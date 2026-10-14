import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/services/review_business_rules.dart';
import '../datasources/firebase_review_data_source.dart';
import '../models/review_model.dart';

/// Firestore-backed implementation of [ReviewRepository].
///
/// CK-019.4
class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._dataSource);

  final FirebaseReviewDataSource _dataSource;

  @override
  Future<Review?> getReview(String reservationId) async {
    _validateIdentifier(reservationId, 'reservationId');
    final document = await _dataSource.getReviewDocument(
      reservationId: reservationId.trim(),
    );

    if (!document.exists) {
      return null;
    }

    return ReviewModel.fromFirestore(document);
  }

  @override
  Future<List<Review>> getReviewsByCoach(String coachId) async {
    _validateIdentifier(coachId, 'coachId');
    final snapshot = await _dataSource.getCoachReviewDocuments(
      coachId: coachId.trim(),
    );

    return snapshot.docs.map(ReviewModel.fromFirestore).toList();
  }

  @override
  Future<void> createReview({
    required String reservationId,
    required String coachId,
    required int rating,
    String? comment,
  }) {
    _validateIdentifier(reservationId, 'reservationId');
    _validateIdentifier(coachId, 'coachId');
    ReviewBusinessRules.validateReviewContent(rating: rating, comment: comment);

    return _dataSource.addReview(
      reservationId: reservationId.trim(),
      coachId: coachId.trim(),
      rating: rating,
      comment: ReviewBusinessRules.normalizeComment(comment),
    );
  }

  @override
  Future<void> updateReview({
    required String reservationId,
    required int rating,
    String? comment,
  }) {
    _validateIdentifier(reservationId, 'reservationId');
    ReviewBusinessRules.validateReviewContent(rating: rating, comment: comment);

    return _dataSource.updateReview(
      reservationId: reservationId.trim(),
      rating: rating,
      comment: ReviewBusinessRules.normalizeComment(comment),
    );
  }

  void _validateIdentifier(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        'El identificador es obligatorio.',
      );
    }
  }
}
