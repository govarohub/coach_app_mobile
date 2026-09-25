abstract final class RouteNames {
  RouteNames._();

  // ---------------------------------------------------------------------------
  // Inicio
  // ---------------------------------------------------------------------------

  static const splash = 'splash';

  static const onboarding = 'onboarding';

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  static const login = 'login';

  static const register = 'register';

  static const forgotPassword = 'forgot-password';

  static const verifyEmail = 'verify-email';

  static const profileSetup = 'profile-setup';

  // ---------------------------------------------------------------------------
  // Home
  // ---------------------------------------------------------------------------

  static const home = 'home';

  // ---------------------------------------------------------------------------
  // Coach
  // ---------------------------------------------------------------------------

  /// Perfil profesional privado del Coach autenticado.
  static const coachProfile = 'coach-profile';

  /// Edición del perfil profesional del Coach.
  static const editCoachProfile = 'edit-coach-profile';

  /// Búsqueda pública de Coaches.
  static const coachSearch = 'coach-search';

  /// Perfil público de un Coach específico.
  static const coachPublicProfile = 'coach-public-profile';

  // ---------------------------------------------------------------------------
  // Reservations
  // ---------------------------------------------------------------------------

  static const reservation = 'reservation';

  static const reservations = 'reservations';

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  static const chat = 'chat';

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  static const profile = 'profile';

  static const editProfile = 'edit-profile';

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  static const settings = 'settings';

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------

  /// Pantalla "Mis Favoritos".
  ///
  /// CK-014.
  static const favorites = 'favorites';
}