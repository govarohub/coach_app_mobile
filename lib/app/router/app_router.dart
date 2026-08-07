import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

import 'app_routes.dart';
import 'route_names.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// App Router
///
/// Configuración centralizada de GoRouter.
///
/// Todas las rutas de la aplicación deberán registrarse aquí.
///
/// CK-003.3
/// ---------------------------------------------------------------------------
abstract final class AppRouter {
  AppRouter._();

  /// Router principal de la aplicación.
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,

    initialLocation: AppRoutes.splash,

    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
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
    ],

    errorBuilder: (context, state) {
      return const Scaffold(
        body: Center(
          child: Text('Página no encontrada'),
        ),
      );
    },
  );
}