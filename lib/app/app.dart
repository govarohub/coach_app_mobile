import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Widget raíz de la aplicación.
///
/// Responsable únicamente de configurar:
///
/// • Theme
/// • Router
///
/// No contiene lógica de negocio.
///
/// CK-003.3
/// ---------------------------------------------------------------------------
class CoachApp extends StatelessWidget {
  const CoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Coach App Mobile',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,

      darkTheme: AppTheme.dark,

      themeMode: ThemeMode.system,

      routerConfig: AppRouter.router,
    );
  }
}