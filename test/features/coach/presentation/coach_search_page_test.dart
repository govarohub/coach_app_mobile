import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/coach/domain/entities/coach_profile.dart';
import 'package:coach_app_mobile/features/coach/domain/entities/coach_public_identity.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_profile_provider.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_search_page.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_search_provider.dart';

void main() {
  testWidgets('shows the coach public photo in search results', (tester) async {
    const photoUrl = 'https://example.com/coach.jpg';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coachSearchProvider.overrideWith(
            (ref) async => [
              const CoachProfile(
                coachId: 'coach-1',
                specialties: ['Entrenamiento funcional'],
                experienceYears: 5,
                hourlyRate: 250,
                rating: 4.8,
                verified: true,
                available: true,
              ),
            ],
          ),
          coachPublicIdentityProvider.overrideWith(
            (ref, coachId) async => const CoachPublicIdentity(
              name: 'Roberto Valenzo',
              photoUrl: photoUrl,
            ),
          ),
        ],
        child: const MaterialApp(home: CoachSearchPage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, photoUrl);
  });
}
