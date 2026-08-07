import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import 'route_names.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// App Router
///
/// Infraestructura base de GoRouter.
///
/// En CK-003.1 únicamente se registra una pantalla temporal
/// para validar que el router funcione correctamente.
///
/// Las rutas funcionales serán agregadas progresivamente
/// en los siguientes CK.
///
/// ---------------------------------------------------------------------------

abstract final class AppRouter {
  AppRouter._();

  /// Configuración global del router.
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,

    initialLocation: AppRoutes.splash,

    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: RouteNames.splash,
        builder: (context, state) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Coach App Mobile',
              ),
            ),
          );
        },
      ),
    ],
  );
}