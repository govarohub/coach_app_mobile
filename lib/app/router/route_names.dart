// ---------------------------------------------------------------------------
// Coach App Mobile
// Route Names
//
// Centraliza los nombres de todas las rutas de la aplicación.
//
// Ningún módulo deberá escribir nombres de rutas como cadenas ("String")
// directamente.
//
// CK-003.1
// ---------------------------------------------------------------------------

abstract final class RouteNames {
  RouteNames._();

  /// Splash
  static const splash = 'splash';

  /// Authentication
  static const login = 'login';
  static const register = 'register';
  static const forgotPassword = 'forgot-password';

  /// Home
  static const home = 'home';

  /// Coach
  static const coachProfile = 'coach-profile';

  /// Reservations
  static const reservation = 'reservation';

  /// Chat
  static const chat = 'chat';

  /// Profile
  static const profile = 'profile';

  /// Settings
  static const settings = 'settings';
}