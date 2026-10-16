import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/services/review_business_rules.dart';
import '../datasources/firebase_review_data_source.dart';
import '../models/review_model.dart';

typedef ReviewClientNameResolver = Future<String> Function(
  String reservationId,
);

/// Firestore-backed implementation of [ReviewRepository].
///
/// CK-019.4
class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._dataSource, [this._clientNameResolver]);

  final FirebaseReviewDataSource _dataSource;
  final ReviewClientNameResolver? _clientNameResolver;

  @override
  Future<Review?> getReview(String reservationId) async {
    _validateIdentifier(reservationId, 'reservationId');
    final document = await _dataSource.getReviewDocument(
      reservationId: reservationId.trim(),
    );

    if (!document.exists) {
      return null;
    }

    return _mapReview(document);
  }

  @override
  Future<List<Review>> getReviewsByCoach(String coachId) async {
    _validateIdentifier(coachId, 'coachId');
    final snapshot = await _dataSource.getCoachReviewDocuments(
      coachId: coachId.trim(),
    );

    final reviews = await Future.wait(snapshot.docs.map(_mapReview));
    reviews.sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return reviews;
  }

  @override
  Future<void> createReview({
    required String reservationId,
    required String clientName,
    required String coachId,
    required int rating,
    String? comment,
  }) {
    _validateIdentifier(reservationId, 'reservationId');
    _validateIdentifier(coachId, 'coachId');
    final normalizedClientName = ReviewBusinessRules.normalizeClientName(
      clientName,
    );
    ReviewBusinessRules.validateReviewContent(rating: rating, comment: comment);

    return _dataSource.addReview(
      reservationId: reservationId.trim(),
      clientName: normalizedClientName,
      coachId: coachId.trim(),
      rating: rating,
      comment: ReviewBusinessRules.normalizeComment(comment),
    );
  }

  @override
  Future<void> updateReview({
    required String reservationId,
    required String clientName,
    required int rating,
    String? comment,
  }) {
    _validateIdentifier(reservationId, 'reservationId');
    final normalizedClientName = ReviewBusinessRules.normalizeClientName(
      clientName,
    );
    ReviewBusinessRules.validateReviewContent(rating: rating, comment: comment);

    return _dataSource.updateReview(
      reservationId: reservationId.trim(),
      clientName: normalizedClientName,
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

  Future<Review> _mapReview(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final storedName = document.data()?['clientName'];
    if (storedName is String &&
        storedName.trim().isNotEmpty &&
        storedName.trim() != 'Cliente') {
      return ReviewModel.fromFirestore(document);
    }

    final resolveClientName = _clientNameResolver;
    if (resolveClientName == null) {
      return ReviewModel.fromFirestore(document);
    }

    String? clientName;
    try {
      clientName = await resolveClientName(document.id);
    } catch (_) {
      // Public review queries must not fail when legacy profile data is private.
    }
    return ReviewModel.fromFirestore(
      document,
      clientNameFallback: clientName,
    );
  }
}
