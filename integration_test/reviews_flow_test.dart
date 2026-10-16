import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:coach_app_mobile/features/authentication/domain/entities/app_user.dart';
import 'package:coach_app_mobile/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:coach_app_mobile/features/reservation/data/datasources/firebase_reservation_datasource.dart';
import 'package:coach_app_mobile/features/reservation/data/repositories/reservation_repository_impl.dart';
import 'package:coach_app_mobile/features/reservation/presentation/pages/reservation_provider.dart';
import 'package:coach_app_mobile/features/reviews/data/datasources/firebase_review_data_source.dart';
import 'package:coach_app_mobile/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:coach_app_mobile/features/reviews/domain/services/review_service.dart';
import 'package:coach_app_mobile/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseAuth auth;
  late FirebaseFirestore firestore;
  late ReviewRepositoryImpl reviewRepository;
  late ReviewService reviewService;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    auth = FirebaseAuth.instance;
    await auth.useAuthEmulator('127.0.0.1', 9099);

    firestore = FirebaseFirestore.instance;
    firestore.useFirestoreEmulator('127.0.0.1', 8080);

    final reservationRepository = ReservationRepositoryImpl(
      dataSource: FirebaseReservationDataSource(firestore: firestore),
    );
    reviewRepository = ReviewRepositoryImpl(
      FirebaseReviewDataSource(firestore: firestore),
    );
    reviewService = ReviewService(reservationRepository, reviewRepository);
  });

  testWidgets(
    'completed-session owner can create/edit a private public review',
    (tester) async {
      final uniqueSuffix = DateTime.now().microsecondsSinceEpoch;
      final ownerEmail = 'review-owner-$uniqueSuffix@example.test';
      const testPassword = 'test-password-123';
      final ownerCredential = await auth.createUserWithEmailAndPassword(
        email: ownerEmail,
        password: testPassword,
      );
      final ownerId = ownerCredential.user!.uid;
      final completedCoachCredential = await auth
          .createUserWithEmailAndPassword(
            email: 'review-coach-$uniqueSuffix@example.test',
            password: testPassword,
          );
      final coachId = completedCoachCredential.user!.uid;
      await auth.signOut();
      await auth.signInWithEmailAndPassword(
        email: ownerEmail,
        password: testPassword,
      );
      final completedReservationId = 'completed-$uniqueSuffix';
      final pendingReservationId = 'pending-$uniqueSuffix';

      await _createReservation(
        firestore: firestore,
        reservationId: completedReservationId,
        clientId: ownerId,
        coachId: coachId,
        status: 'pending',
      );
      await _createReservation(
        firestore: firestore,
        reservationId: pendingReservationId,
        clientId: ownerId,
        coachId: coachId,
        status: 'pending',
      );
      final completedReservationReference = firestore
          .collection('reservations')
          .doc(completedReservationId);

      await expectLater(
        completedReservationReference.update({'status': 'completed'}),
        throwsA(isA<FirebaseException>()),
      );

      await auth.signOut();
      await auth.createUserWithEmailAndPassword(
        email: 'review-other-coach-$uniqueSuffix@example.test',
        password: testPassword,
      );
      await expectLater(
        completedReservationReference.update({'status': 'completed'}),
        throwsA(isA<FirebaseException>()),
      );

      await auth.signOut();
      await auth.signInWithEmailAndPassword(
        email: 'review-coach-$uniqueSuffix@example.test',
        password: testPassword,
      );
      final providerContainer = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              AppUser(
                id: coachId,
                email: 'review-coach-$uniqueSuffix@example.test',
                role: 'coach',
              ),
            ),
          ),
        ],
      );
      addTearDown(providerContainer.dispose);

      await providerContainer
          .read(reservationControllerProvider.notifier)
          .completeReservationAsCoach(reservationId: completedReservationId);

      final completedReservation = await completedReservationReference.get();
      expect(completedReservation.data()?['status'], 'completed');

      await auth.signOut();
      await auth.signInWithEmailAndPassword(
        email: ownerEmail,
        password: testPassword,
      );

      final eligibility = await reviewService.checkEligibility(
        reservationId: completedReservationId,
        authenticatedClientId: ownerId,
      );
      expect(eligibility.existingReview, isNull);

      await reviewService.submitReview(
        reservationId: completedReservationId,
        authenticatedClientId: ownerId,
        clientName: 'Alberto Valenzo',
        rating: 4,
        comment: '  Buena sesión  ',
      );

      final reviewReference = firestore
          .collection('reviews')
          .doc(completedReservationId);
      final createdReview = await reviewReference.get();
      expect(createdReview.data()?['rating'], 4);
      expect(createdReview.data()?['clientName'], 'Alberto Valenzo');
      expect(createdReview.data()?['comment'], 'Buena sesión');
      expect(createdReview.data()?.containsKey('clientId'), isFalse);

      await reviewService.submitReview(
        reservationId: completedReservationId,
        authenticatedClientId: ownerId,
        clientName: 'Alberto Valenzo',
        rating: 5,
      );

      final editedReview = await reviewReference.get();
      expect(editedReview.data()?['rating'], 5);
      expect(editedReview.data()?.containsKey('comment'), isFalse);
      expect(editedReview.data()?.containsKey('clientId'), isFalse);

      await expectLater(
        reviewRepository.createReview(
          reservationId: completedReservationId,
          clientName: 'Alberto Valenzo',
          coachId: coachId,
          rating: 3,
        ),
        throwsA(anything),
      );
      final reviewsAfterDuplicateAttempt = await firestore
          .collection('reviews')
          .where('reservationId', isEqualTo: completedReservationId)
          .get();
      expect(reviewsAfterDuplicateAttempt.docs.map((document) => document.id), [
        completedReservationId,
      ]);

      await expectLater(
        reviewService.submitReview(
          reservationId: pendingReservationId,
          authenticatedClientId: ownerId,
          clientName: 'Alberto Valenzo',
          rating: 5,
        ),
        throwsA(isA<StateError>()),
      );

      await expectLater(
        reviewRepository.createReview(
          reservationId: pendingReservationId,
          clientName: 'Alberto Valenzo',
          coachId: coachId,
          rating: 5,
        ),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );

      final otherCredential = await auth.createUserWithEmailAndPassword(
        email: 'review-other-$uniqueSuffix@example.test',
        password: testPassword,
      );
      await expectLater(
        reviewService.checkEligibility(
          reservationId: completedReservationId,
          authenticatedClientId: otherCredential.user!.uid,
        ),
        throwsA(isA<StateError>()),
      );

      await auth.signOut();
      final publicReview = await reviewReference.get();
      expect(publicReview.data()?['rating'], 5);

      final publicCoachReviews = await reviewRepository.getReviewsByCoach(
        coachId,
      );
      expect(
        publicCoachReviews.map((review) => review.reservationId),
        contains(completedReservationId),
      );

      await expectLater(
        reviewReference.delete(),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );
    },
  );
}

Future<void> _createReservation({
  required FirebaseFirestore firestore,
  required String reservationId,
  required String clientId,
  required String coachId,
  required String status,
}) {
  return firestore.collection('reservations').doc(reservationId).set({
    'reservationId': reservationId,
    'clientId': clientId,
    'coachId': coachId,
    'scheduleId': 'schedule-$reservationId',
    'status': status,
    'amount': 100.0,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
