import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

/// ---------------------------------------------------------------------------
/// OnboardingPage
///
/// Presenta al usuario las características principales de Coach antes
/// de acceder a la aplicación.
///
/// Responsabilidades:
/// - Mostrar las páginas informativas iniciales.
/// - Permitir avanzar entre páginas.
/// - Permitir omitir el onboarding.
/// - Permitir finalizar el onboarding.
/// - Navegar hacia Login al terminar.
///
/// No contiene:
/// - Autenticación.
/// - Registro.
/// - Persistencia.
/// - Firebase.
/// - Lógica de negocio.
///
/// La autenticación será implementada posteriormente en CK-007.
/// ---------------------------------------------------------------------------
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

/// Estado interno del onboarding.
///
/// Mantiene únicamente el índice de la página actualmente visible.
class _OnboardingPageState extends State<OnboardingPage> {
  /// Controlador utilizado para cambiar entre las páginas del onboarding.
  final PageController _pageController = PageController();

  /// Índice de la página actualmente visible.
  int _currentPage = 0;

  /// Contenido estático de las páginas del onboarding.
  ///
  /// Se mantiene dentro de esta pantalla porque en CK-006 solamente
  /// necesitamos presentar información inicial.
  static const List<_OnboardingItem> _items = [
    _OnboardingItem(
      icon: Icons.psychology_outlined,
      title: 'Encuentra tu Coach',
      description:
          'Descubre profesionales que pueden acompañarte en tus objetivos personales y profesionales.',
    ),
    _OnboardingItem(
      icon: Icons.calendar_month_outlined,
      title: 'Agenda tus sesiones',
      description:
          'Consulta la disponibilidad de tu Coach y reserva sesiones de manera sencilla.',
    ),
    _OnboardingItem(
      icon: Icons.trending_up_outlined,
      title: 'Avanza hacia tus objetivos',
      description:
          'Mantén el seguimiento de tus sesiones y continúa trabajando en tu crecimiento.',
    ),
  ];

  /// Indica si estamos mostrando la última página.
  bool get _isLastPage => _currentPage == _items.length - 1;

  /// Avanza a la siguiente página o finaliza el onboarding.
  void _nextPage() {
    if (_isLastPage) {
      _finishOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Omite el onboarding y continúa hacia Login.
  void _skipOnboarding() {
    _finishOnboarding();
  }

  /// Finaliza el onboarding.
  ///
  /// CK-007 implementará posteriormente el flujo real de autenticación.
  /// Por ahora navegamos hacia la ruta Login ya definida por CK-003.
  void _finishOnboarding() {
    context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    // Liberamos el controlador cuando la pantalla deja de existir.
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // Botón para omitir el onboarding.
            // -----------------------------------------------------------------
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: const Text('Omitir'),
              ),
            ),

            // -----------------------------------------------------------------
            // Área principal de las páginas.
            // -----------------------------------------------------------------
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icono representativo de la sección.
                        Icon(item.icon, size: 96),

                        const SizedBox(height: 32),

                        // Título de la página.
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),

                        const SizedBox(height: 16),

                        // Descripción de la página.
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // -----------------------------------------------------------------
            // Indicadores de progreso.
            // -----------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_items.length, (index) {
                final isActive = index == _currentPage;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // Botón principal.
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextPage,
                  child: Text(_isLastPage ? 'Comenzar' : 'Siguiente'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Modelo privado del contenido del onboarding.
///
/// Es deliberadamente privado porque solamente representa datos estáticos
/// utilizados por OnboardingPage.
///
/// No es un modelo de dominio y no debe trasladarse a shared/models.
/// ---------------------------------------------------------------------------
class _OnboardingItem {
  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
