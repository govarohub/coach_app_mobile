import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/reservation/domain/entities/reservation.dart';
import 'package:coach_app_mobile/features/reviews/domain/entities/review.dart';
import 'package:coach_app_mobile/features/reviews/domain/services/review_service.dart';
import 'package:coach_app_mobile/features/reviews/presentation/pages/client_review_page.dart';
import 'package:coach_app_mobile/features/reviews/presentation/review_providers.dart';

void main() {
  testWidgets('prefills an existing review for editing', (tester) async {
    final eligibility = _eligibility(
      existingReview: _review(rating: 4, comment: 'Buena sesión'),
    );

    await tester.pumpWidget(
      _testApp(eligibility: eligibility, controller: _FakeReviewController()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actualiza tu calificación'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Buena sesión',
    );
    expect(find.byTooltip('4 estrellas'), findsOneWidget);
  });

  testWidgets('submits the selected rating and optional comment', (
    tester,
  ) async {
    final controller = _FakeReviewController();

    await tester.pumpWidget(
      _testApp(eligibility: _eligibility(), controller: controller),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('5 estrellas'));
    await tester.enterText(find.byType(TextField), 'Excelente sesión');
    await tester.tap(find.text('Enviar reseña'));
    await tester.pumpAndSettle();

    expect(controller.reservationId, 'reservation-1');
    expect(controller.rating, 5);
    expect(controller.comment, 'Excelente sesión');
  });
}

Widget _testApp({
  required ReviewEligibility eligibility,
  required _FakeReviewController controller,
}) {
  return ProviderScope(
    overrides: [
      reviewEligibilityProvider.overrideWith(
        (ref, reservationId) async => eligibility,
      ),
      reviewControllerProvider.overrideWith(() => controller),
    ],
    child: const MaterialApp(
      home: ClientReviewPage(reservationId: 'reservation-1'),
    ),
  );
}

ReviewEligibility _eligibility({Review? existingReview}) {
  return ReviewEligibility(
    reservation: Reservation(
      reservationId: 'reservation-1',
      clientId: 'client-1',
      coachId: 'coach-1',
      scheduleId: 'schedule-1',
      status: 'completed',
      amount: 100,
      createdAt: DateTime(2026, 10, 1),
    ),
    existingReview: existingReview,
  );
}

Review _review({required int rating, required String comment}) {
  final now = DateTime(2026, 10, 13);
  return Review(
    reservationId: 'reservation-1',
    coachId: 'coach-1',
    rating: rating,
    comment: comment,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeReviewController extends ReviewController {
  String? reservationId;
  int? rating;
  String? comment;

  @override
  Future<void> build() async {}

  @override
  Future<void> submitReview({
    required String reservationId,
    required int rating,
    String? comment,
  }) async {
    this.reservationId = reservationId;
    this.rating = rating;
    this.comment = comment;
  }
}
