import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/providers/auth_state_provider.dart';
import '../../reservation/presentation/pages/reservation_provider.dart';
import '../data/datasources/firebase_review_data_source.dart';
import '../data/repositories/review_repository_impl.dart';
import '../domain/entities/coach_review_summary.dart';
import '../domain/entities/review.dart';
import '../domain/repositories/review_repository.dart';
import '../domain/services/review_service.dart';

final firebaseReviewDataSourceProvider = Provider<FirebaseReviewDataSource>((
  ref,
) {
  return FirebaseReviewDataSource();
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.watch(firebaseReviewDataSourceProvider));
});

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(
    ref.watch(reservationRepositoryProvider),
    ref.watch(reviewRepositoryProvider),
  );
});

/// Loads a reservation and its existing review only for its authenticated owner.
final reviewEligibilityProvider =
    FutureProvider.family<ReviewEligibility, String>((
      ref,
      reservationId,
    ) async {
      final authState = await ref.watch(authStateProvider.future);
      if (authState == null) {
        throw StateError('No existe una sesión de usuario activa.');
      }

      return ref
          .watch(reviewServiceProvider)
          .checkEligibility(
            reservationId: reservationId,
            authenticatedClientId: authState.id,
          );
    });

/// Retrieves public reviews ordered by creation time, newest first.
final coachReviewsProvider = FutureProvider.family<List<Review>, String>((
  ref,
  coachId,
) async {
  return ref.watch(reviewRepositoryProvider).getReviewsByCoach(coachId);
});

final coachReviewSummaryProvider =
    FutureProvider.family<CoachReviewSummary, String>((ref, coachId) async {
      final reviews = await ref.watch(coachReviewsProvider(coachId).future);
      return CoachReviewSummary.fromReviews(reviews);
    });

class ReviewController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submitReview({
    required String reservationId,
    required int rating,
    String? comment,
  }) async {
    state = const AsyncLoading();

    try {
      final authState = await ref.read(authStateProvider.future);
      if (authState == null) {
        throw StateError('No existe una sesión de usuario activa.');
      }

      final eligibility = await ref
          .read(reviewServiceProvider)
          .submitReview(
            reservationId: reservationId,
            authenticatedClientId: authState.id,
            rating: rating,
            comment: comment,
          );

      ref.invalidate(reviewEligibilityProvider(reservationId));
      ref.invalidate(coachReviewsProvider(eligibility.reservation.coachId));
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final reviewControllerProvider = AsyncNotifierProvider<ReviewController, void>(
  ReviewController.new,
);
