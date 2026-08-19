import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Páginas de autenticación.
import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/profile_setup_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/verify_email_page.dart';

// Página de inicio.
import '../../features/home/presentation/pages/home_page.dart';

// Onboarding y Splash.
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

import 'app_routes.dart';
import 'route_names.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Configuración global del sistema de navegación.
///
/// Reglas:
///
/// • Todas las rutas deben registrarse aquí.
/// • Ningún módulo utilizará Navigator.push().
/// • Ningún módulo declarará rutas propias.
/// • Todas las redirecciones futuras se implementarán aquí.
///
/// Preparado para:
///
/// CK-004 Riverpod
/// CK-005 Firebase
/// CK-007 Auth
///
/// ---------------------------------------------------------------------------
abstract final class AppRouter {
  AppRouter._();

  /// Router oficial de la aplicación.
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,

    initialLocation: AppRoutes.splash,

    // -----------------------------------------------------------------------
    // Redirecciones globales.
    //
    // En CK-007 se implementará la validación de autenticación.
    // Por ahora no existe ninguna regla de redirección.
    // -----------------------------------------------------------------------
    redirect: (context, state) {
      return null;
    },

    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),

      GoRoute(
        path: AppRoutes.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

      GoRoute(
        path: AppRoutes.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

      GoRoute(
        path: AppRoutes.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: AppRoutes.home,
        name: RouteNames.home,
        builder: (context, state) => const HomePage(),
      ),

      GoRoute(
        path: AppRoutes.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),

      GoRoute(
        path: AppRoutes.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      GoRoute(
        path: AppRoutes.verifyEmail,
        name: RouteNames.verifyEmail,
        builder: (context, state) => const VerifyEmailPage(),
      ),

      GoRoute(
        path: AppRoutes.profileSetup,
        name: RouteNames.profileSetup,
        builder: (context, state) => const ProfileSetupPage(),
      ),
    ],

    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(
            'Ruta no encontrada:\n${state.uri}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );
}
