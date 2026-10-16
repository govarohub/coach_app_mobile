import '../entities/review.dart';

/// Pure domain rules for review content, eligibility, and editing.
///
/// CK-019.3
class ReviewBusinessRules {
  ReviewBusinessRules._();

  static const int minimumRating = 1;
  static const int maximumRating = 5;
  static const int maximumCommentLength = 500;
  static const int maximumClientNameLength = 100;

  static String normalizeClientName(String? clientName) {
    final normalizedName = clientName?.trim();
    if (normalizedName == null || normalizedName.isEmpty) {
      throw ArgumentError(
        'El perfil del cliente debe tener un nombre antes de reseñar.',
      );
    }
    if (normalizedName.runes.length > maximumClientNameLength) {
      throw ArgumentError.value(
        clientName,
        'clientName',
        'El nombre público no puede superar 100 caracteres.',
      );
    }
    return normalizedName;
  }

  static String resolveClientName({
    required String? storedName,
    required String? profileName,
  }) {
    final normalizedStoredName = storedName?.trim();
    if (normalizedStoredName != null &&
        normalizedStoredName.isNotEmpty &&
        normalizedStoredName != 'Cliente') {
      return normalizeClientName(normalizedStoredName);
    }

    final normalizedProfileName = profileName?.trim();
    if (normalizedProfileName == null || normalizedProfileName.isEmpty) {
      return '';
    }
    return normalizeClientName(normalizedProfileName);
  }

  /// Rejects values outside 1-5 and non-integer numeric values.
  static void validateRating(num rating) {
    if (!rating.isFinite ||
        rating % 1 != 0 ||
        rating < minimumRating ||
        rating > maximumRating) {
      throw ArgumentError.value(
        rating,
        'rating',
        'La calificación debe ser un entero entre 1 y 5.',
      );
    }
  }

  /// Trims a comment, converts empty text to null, and enforces the limit.
  static String? normalizeComment(String? comment) {
    final normalizedComment = comment?.trim();

    if (normalizedComment == null || normalizedComment.isEmpty) {
      return null;
    }

    if (normalizedComment.runes.length > maximumCommentLength) {
      throw ArgumentError.value(
        comment,
        'comment',
        'El comentario no puede superar 500 caracteres.',
      );
    }

    return normalizedComment;
  }

  /// Validates content that can be created or edited by a client.
  static void validateReviewContent({required num rating, String? comment}) {
    validateRating(rating);
    normalizeComment(comment);
  }

  /// Validates all intrinsic fields of a review entity.
  static void validateReview(Review review) {
    _validateIdentifier(review.reservationId, 'reservationId');
    _validateIdentifier(review.coachId, 'coachId');
    if (review.clientName.trim().isNotEmpty &&
        review.clientName.trim() != 'Cliente') {
      normalizeClientName(review.clientName);
    }

    validateReviewContent(rating: review.rating, comment: review.comment);
    validateTimestamps(
      createdAt: review.createdAt,
      updatedAt: review.updatedAt,
    );
  }

  /// Checks that the signed-in client may review the specified reservation.
  static void validateReviewEligibility({
    required String reservationStatus,
    required String reservationClientId,
    required String reservationCoachId,
    required String authenticatedClientId,
  }) {
    _validateIdentifier(reservationClientId, 'clientId');
    _validateIdentifier(reservationCoachId, 'coachId');
    _validateIdentifier(authenticatedClientId, 'authenticatedClientId');

    if (reservationStatus.trim() != 'completed') {
      throw StateError('Solo se pueden reseñar sesiones completadas.');
    }

    if (reservationClientId.trim() != authenticatedClientId.trim()) {
      throw StateError(
        'Solo el cliente propietario de la reserva puede reseñarla.',
      );
    }

    if (authenticatedClientId.trim() == reservationCoachId.trim()) {
      throw StateError('Un Coach no puede reseñar su propia sesión.');
    }
  }

  /// Prevents editing the reservation, owner, coach, or original creation time.
  static void validateReviewUpdate({
    required Review existingReview,
    required String reservationId,
    required String reservationClientId,
    required String clientName,
    required String coachId,
    required DateTime createdAt,
    required String authenticatedClientId,
    required num rating,
    String? comment,
  }) {
    if (reservationClientId.trim() != authenticatedClientId.trim()) {
      throw StateError('Solo el cliente autor puede editar esta reseña.');
    }

    if (reservationId.trim() != existingReview.reservationId ||
        coachId.trim() != existingReview.coachId ||
        createdAt != existingReview.createdAt) {
      throw StateError(
        'No se pueden cambiar la reserva, el Coach ni la fecha de creación.',
      );
    }

    if (authenticatedClientId.trim() == coachId.trim()) {
      throw StateError('Un Coach no puede reseñar su propia sesión.');
    }

    if (clientName.trim().isNotEmpty && clientName.trim() != 'Cliente') {
      normalizeClientName(clientName);
    }
    validateReviewContent(rating: rating, comment: comment);
  }

  /// Ensures persisted timestamps preserve creation/edit chronology.
  static void validateTimestamps({
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt no puede ser anterior a createdAt.');
    }
  }

  static void _validateIdentifier(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        'El identificador es obligatorio.',
      );
    }
  }
}
