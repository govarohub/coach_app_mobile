// ---------------------------------------------------------------------------
// Coach App Mobile
// Routes
//
// Centraliza las rutas (paths) utilizadas por GoRouter.
//
// Ninguna pantalla deberá escribir paths directamente.
//
// CK-003.1
// ---------------------------------------------------------------------------

abstract final class AppRoutes {
  AppRoutes._();

  static const splash = '/';

  /// Pantalla de introducción inicial.
  static const onboarding = '/onboarding';

  static const login = '/login';

  static const register = '/register';

  static const forgotPassword = '/forgot-password';

  static const home = '/home';

  static const coachProfile = '/coach-profile';

  static const reservation = '/reservation';

  static const chat = '/chat';

  static const profile = '/profile';

  static const settings = '/settings';
}
