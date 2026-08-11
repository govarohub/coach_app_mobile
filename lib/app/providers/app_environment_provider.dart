import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Provider de configuración del entorno de ejecución.
///
/// Este provider NO representa estado de negocio.
///
/// Su responsabilidad es exponer información de infraestructura que puede
/// necesitar la aplicación para conocer el entorno en el que está ejecutándose.
///
/// Valores posibles:
/// - development
/// - staging
/// - production
///
/// En esta etapa el entorno se determina mediante una variable de compilación.
/// ---------------------------------------------------------------------------
final appEnvironmentProvider = Provider<String>((ref) {
  // String.fromEnvironment permite definir el entorno mediante --dart-define.
  //
  // Si no se proporciona ningún valor, utilizamos "development" como valor
  // seguro para el trabajo local.
  return const String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
});