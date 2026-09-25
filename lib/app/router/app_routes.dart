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

  /// Perfil profesional privado del Coach autenticado.
  static const coachProfile = '/coach-profile';

  /// Edición del perfil profesional del Coach.
  static const editCoachProfile = '/coach-profile/edit';

  /// Búsqueda pública de Coaches.
  static const coachSearch = '/coach-search';

  /// Perfil público de un Coach específico.
  ///
  /// El parámetro coachId identifica al Coach que se desea consultar.
  static const coachPublicProfile =
      '/coach-public-profile/:coachId';

  // ---------------------------------------------------------------------------
  // Reservations
  // ---------------------------------------------------------------------------

  static const reservation = '/reservation';

  static const reservations = '/reservations';

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  static const chat = '/chat';

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  /// Perfil principal del usuario.
  static const profile = '/profile';

  /// Edición del perfil del usuario.
  static const editProfile = '/profile/edit';

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  static const settings = '/settings';

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------

  /// Pantalla "Mis Favoritos".
  ///
  /// CK-014.
  static const favorites = '/favorites';
}