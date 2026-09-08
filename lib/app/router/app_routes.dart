abstract final class AppRoutes {
  AppRoutes._();

  // ---------------------------------------------------------------------------
  // Inicio
  // ---------------------------------------------------------------------------

  static const splash = '/';

  static const onboarding = '/onboarding';

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  static const login = '/login';

  static const register = '/register';

  static const forgotPassword = '/forgot-password';

  static const verifyEmail = '/verify-email';

  static const profileSetup = '/profile/setup';

  // ---------------------------------------------------------------------------
  // Home
  // ---------------------------------------------------------------------------

  static const home = '/home';

  // ---------------------------------------------------------------------------
  // Coach
  // ---------------------------------------------------------------------------

  static const coachProfile = '/coach-profile';

  // ---------------------------------------------------------------------------
  // Reservations
  // ---------------------------------------------------------------------------

  static const reservation = '/reservation';

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  static const chat = '/chat';

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  /// Pantalla principal del perfil del usuario.
  static const profile = '/profile';

  /// Pantalla para editar los datos personales del usuario.
  static const editProfile = '/profile/edit';

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  static const settings = '/settings';

  // -------------------------------------------------------------------------
  // Dashboard
  // -------------------------------------------------------------------------

  /// Búsqueda de coaches.
  ///
  /// La pantalla será implementada en CK-012.
  static const coachSearch = '/coach-search';

  /// Reservaciones del cliente.
  ///
  /// La funcionalidad completa será implementada en CK-017.
  static const reservations = '/reservations';

  /// Coaches favoritos.
  ///
  /// La funcionalidad será implementada en CK-014.
  static const favorites = '/favorites';

  static const editCoachProfile = '/coach-profile/edit';
}
