import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore access for the root `reviews` collection.
///
/// CK-019.4
class FirebaseReviewDataSource {
  FirebaseReviewDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviewsCollection =>
      _firestore.collection('reviews');

  Future<DocumentSnapshot<Map<String, dynamic>>> getReviewDocument({
    required String reservationId,
  }) {
    _validateIdentifier(reservationId, 'reservationId');
    return _reviewsCollection.doc(reservationId.trim()).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCoachReviewDocuments({
    required String coachId,
  }) {
    _validateIdentifier(coachId, 'coachId');
    return _reviewsCollection
        .where('coachId', isEqualTo: coachId.trim())
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<void> addReview({
    required String reservationId,
    required String coachId,
    required int rating,
    String? comment,
  }) async {
    _validateIdentifier(reservationId, 'reservationId');
    _validateIdentifier(coachId, 'coachId');

    final document = _reviewsCollection.doc(reservationId.trim());
    await _firestore.runTransaction<void>((transaction) async {
      final existingDocument = await transaction.get(document);
      if (existingDocument.exists) {
        throw StateError('La reserva ya tiene una reseña.');
      }

      transaction.set(document, {
        'reservationId': document.id,
        'coachId': coachId.trim(),
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateReview({
    required String reservationId,
    required int rating,
    String? comment,
  }) {
    _validateIdentifier(reservationId, 'reservationId');

    return _reviewsCollection.doc(reservationId.trim()).update({
      'clientId': FieldValue.delete(),
      'rating': rating,
      'comment': comment == null || comment.isEmpty
          ? FieldValue.delete()
          : comment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
