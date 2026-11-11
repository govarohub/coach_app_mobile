import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:coach_app_mobile/features/authentication/presentation/pages/login_page.dart';

void main() {
  testWidgets('toggles password visibility from the eye button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    final passwordField = tester.widget<EditableText>(
      find.byType(EditableText).last,
    );
    expect(passwordField.obscureText, isTrue);
    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();

    final visiblePasswordField = tester.widget<EditableText>(
      find.byType(EditableText).last,
    );
    expect(visiblePasswordField.obscureText, isFalse);
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });
}

class _FakeAuthController extends AuthController {
  @override
  Future<void> build() async {}
}
