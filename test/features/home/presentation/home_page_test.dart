import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/authentication/domain/entities/app_user.dart';
import 'package:coach_app_mobile/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:coach_app_mobile/features/home/presentation/pages/home_page.dart';
import 'package:coach_app_mobile/features/profile/domain/entities/client_profile.dart';
import 'package:coach_app_mobile/features/profile/presentation/pages/profile_provider.dart';

void main() {
  testWidgets('shows the signed-in client profile photo on home', (
    tester,
  ) async {
    const photoUrl = 'https://example.com/client.jpg';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AppUser(
                id: 'client-1',
                email: 'client@example.com',
                displayName: 'Cliente',
              ),
            ),
          ),
          profileProvider.overrideWith(
            () => _FakeProfileNotifier(photoUrl),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, photoUrl);
  });
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this.photoUrl);

  final String photoUrl;

  @override
  Future<ClientProfile?> build() async {
    return ClientProfile(
      uid: 'client-1',
      email: 'client@example.com',
      name: 'Cliente',
      role: 'client',
      photoUrl: photoUrl,
      status: 'active',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }
}
