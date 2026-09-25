import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Authentication
// ---------------------------------------------------------------------------

import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/profile_setup_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/verify_email_page.dart';

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

import '../../features/home/presentation/pages/home_page.dart';

// ---------------------------------------------------------------------------
// Onboarding / Splash
// ---------------------------------------------------------------------------

import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';

// ---------------------------------------------------------------------------
// Coach
// ---------------------------------------------------------------------------

import '../../features/coach/presentation/pages/coach_profile_page.dart';
import '../../features/coach/presentation/pages/edit_coach_profile_page.dart';
import '../../features/coach/presentation/pages/coach_search_page.dart';
import '../../features/coach/presentation/pages/coach_public_profile_page.dart';

// ---------------------------------------------------------------------------
// Favorites
// ---------------------------------------------------------------------------

import '../../features/favorites/presentation/pages/favorites_page.dart';

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

import 'app_routes.dart';
import 'route_names.dart';

abstract final class AppRouter {
  AppRouter._();

  /// Router oficial de la aplicación.
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,

    // -------------------------------------------------------------------------
    // Ruta inicial
    // -------------------------------------------------------------------------

    initialLocation: AppRoutes.splash,

    // -------------------------------------------------------------------------
    // Redirecciones globales
    // -------------------------------------------------------------------------

    /// Actualmente no se modifica la navegación mediante redirecciones.
    redirect: (context, state) {
      return null;
    },

    // -------------------------------------------------------------------------
    // Rutas
    // -------------------------------------------------------------------------

    routes: <RouteBase>[
      // -----------------------------------------------------------------------
      // Splash
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // -----------------------------------------------------------------------
      // Onboarding
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

      // -----------------------------------------------------------------------
      // Login
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),

      // -----------------------------------------------------------------------
      // Home
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.home,
        name: RouteNames.home,
        builder: (context, state) => const HomePage(),
      ),

      // -----------------------------------------------------------------------
      // Register
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),

      // -----------------------------------------------------------------------
      // Forgot password
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // -----------------------------------------------------------------------
      // Verify email
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.verifyEmail,
        name: RouteNames.verifyEmail,
        builder: (context, state) => const VerifyEmailPage(),
      ),

      // -----------------------------------------------------------------------
      // Profile setup
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.profileSetup,
        name: RouteNames.profileSetup,
        builder: (context, state) => const ProfileSetupPage(),
      ),

      // -----------------------------------------------------------------------
      // Profile
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.profile,
        name: RouteNames.profile,
        builder: (context, state) => const ProfilePage(),
      ),

      // -----------------------------------------------------------------------
      // Edit profile
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.editProfile,
        name: RouteNames.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),

      // -----------------------------------------------------------------------
      // Coach profile
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.coachProfile,
        name: RouteNames.coachProfile,
        builder: (context, state) => const CoachProfilePage(),
      ),

      // -----------------------------------------------------------------------
      // Edit coach profile
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.editCoachProfile,
        name: RouteNames.editCoachProfile,
        builder: (context, state) => const EditCoachProfilePage(),
      ),

      // -----------------------------------------------------------------------
      // Coach search
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.coachSearch,
        name: RouteNames.coachSearch,
        builder: (context, state) => const CoachSearchPage(),
      ),

      // -----------------------------------------------------------------------
      // CK-013
      //
      // Perfil público del Coach.
      //
      // Recibe:
      //
      // /coach-public-profile/:coachId
      //
      // El coachId se obtiene de los pathParameters.
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.coachPublicProfile,
        name: RouteNames.coachPublicProfile,

        builder: (context, state) {
          final coachId = state.pathParameters['coachId'];

          if (coachId == null || coachId.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text('Identificador del Coach no válido.'),
              ),
            );
          }

          // coachId proviene de los parámetros de navegación,
          // por lo que esta instancia no puede ser const.
          return CoachPublicProfilePage(
            coachId: coachId,
          );
        },

      ),

      // -----------------------------------------------------------------------
      // CK-014
      //
      // Mis Favoritos.
      //
      // Esta ruta corrige el error observado:
      //
      // Ruta no encontrada:
      // /favorites
      // -----------------------------------------------------------------------

      GoRoute(
        path: AppRoutes.favorites,
        name: RouteNames.favorites,
        builder: (context, state) => const FavoritesPage(),
      ),
    ],

    // -------------------------------------------------------------------------
    // Error de navegación
    // -------------------------------------------------------------------------

    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Ruta no encontrada:\n${state.uri}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    },
  );
}