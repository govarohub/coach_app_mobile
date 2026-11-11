import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:coach_app_mobile/features/authentication/domain/entities/app_user.dart';
import 'package:coach_app_mobile/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:coach_app_mobile/features/authentication/presentation/pages/coach_register_page.dart';
import 'package:coach_app_mobile/features/authentication/presentation/pages/register_page.dart';

void main() {
  for (final isCoach in [false, true]) {
    final role = isCoach ? 'coach' : 'cliente';

    testWidgets('$role valida la confirmación antes de registrar', (
      tester,
    ) async {
      final controller = _FakeAuthController();
      await _pumpForm(tester, controller, isCoach: isCoach);
      await _enter(tester, 'Nombre', 'Ana');
      await _enter(tester, 'Apellidos', 'López');
      await _enter(tester, 'Correo electrónico', 'ana@example.com');
      await _enter(tester, 'Contraseña', 'clave123');

      await _submit(tester);
      expect(find.text('Repite tu contraseña.'), findsOneWidget);
      expect(controller.calls, 0);

      await _enter(tester, 'Repetir contraseña', 'diferente');
      await _submit(tester);
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(controller.calls, 0);

      await _enter(tester, 'Contraseña', 'corta');
      await _enter(tester, 'Repetir contraseña', 'corta');
      await _submit(tester);
      expect(
        find.text('La contraseña debe tener al menos 6 caracteres.'),
        findsOneWidget,
      );
      expect(controller.calls, 0);

      await _enter(tester, 'Contraseña', 'clave123');
      await _enter(tester, 'Repetir contraseña', 'clave123');
      await _enter(tester, 'Contraseña', 'clave456');
      await _submit(tester);
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(controller.calls, 0);

      await _enter(tester, 'Contraseña', 'clave123');
      await _enter(tester, 'Repetir contraseña', 'clave123');
      await _submit(tester);
      expect(controller.calls, 1);
      expect(controller.role, isCoach ? 'coach' : 'client');
      expect(controller.password, 'clave123');
      expect(find.text('Verificar correo'), findsOneWidget);
    });

    testWidgets('$role muestra y oculta ambos campos por separado', (
      tester,
    ) async {
      await _pumpForm(tester, _FakeAuthController(), isCoach: isCoach);
      await _enter(tester, 'Contraseña', 'clave123');
      await _enter(tester, 'Repetir contraseña', 'clave123');

      expect(_obscured(tester, 'Contraseña'), isTrue);
      expect(_obscured(tester, 'Repetir contraseña'), isTrue);

      await tester.ensureVisible(find.byTooltip('Mostrar contraseña'));
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(_obscured(tester, 'Contraseña'), isFalse);
      expect(_obscured(tester, 'Repetir contraseña'), isTrue);

      await tester.ensureVisible(find.byTooltip('Mostrar contraseña repetida'));
      await tester.tap(find.byTooltip('Mostrar contraseña repetida'));
      await tester.pump();
      expect(_obscured(tester, 'Repetir contraseña'), isFalse);

      await tester.tap(find.byTooltip('Ocultar contraseña repetida'));
      await tester.pump();
      expect(_obscured(tester, 'Repetir contraseña'), isTrue);
      await tester.tap(find.byTooltip('Ocultar contraseña'));
      await tester.pump();
      expect(_obscured(tester, 'Contraseña'), isTrue);
    });

    testWidgets('$role actualiza el indicador de validación al escribir', (
      tester,
    ) async {
      await _pumpForm(tester, _FakeAuthController(), isCoach: isCoach);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.cancel), findsNothing);

      await _enter(tester, 'Contraseña', 'clave123');
      await _enter(tester, 'Repetir contraseña', 'diferente');
      expect(tester.widget<Icon>(find.byIcon(Icons.cancel)).color,
          Colors.red.shade700);
      expect(find.byIcon(Icons.check_circle), findsNothing);

      await _enter(tester, 'Repetir contraseña', 'clave123');
      expect(tester.widget<Icon>(find.byIcon(Icons.check_circle)).color,
          Colors.green.shade700);
      expect(find.byIcon(Icons.cancel), findsNothing);

      await _enter(tester, 'Contraseña', 'corta');
      await _enter(tester, 'Repetir contraseña', 'corta');
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);

      await _enter(tester, 'Contraseña', 'clave123');
      await _enter(tester, 'Repetir contraseña', 'clave123');
      await _enter(tester, 'Contraseña', 'clave456');
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);

      await _enter(tester, 'Repetir contraseña', '');
      expect(find.byIcon(Icons.cancel), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  }
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is TextField && widget.decoration?.labelText == label,
);

bool _obscured(WidgetTester tester, String label) {
  return tester
      .widget<EditableText>(
        find.descendant(of: _field(label), matching: find.byType(EditableText)),
      )
      .obscureText;
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_field(label), value);
  await tester.pump();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Registrarme'));
  await tester.tap(find.text('Registrarme'));
  await tester.pumpAndSettle();
}

Future<void> _pumpForm(
  WidgetTester tester,
  _FakeAuthController controller, {
  required bool isCoach,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            isCoach ? const CoachRegisterPage() : const RegisterPage(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) =>
            const Scaffold(body: Text('Verificar correo')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => controller)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeAuthController extends AuthController {
  int calls = 0;
  String? role;
  String? password;

  @override
  Future<void> build() async {}

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    calls++;
    role = 'client';
    this.password = password;
    return AppUser(id: 'user', email: email);
  }

  @override
  Future<AppUser> signUpCoach({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    calls++;
    role = 'coach';
    this.password = password;
    return AppUser(id: 'user', email: email, role: 'coach');
  }
}
