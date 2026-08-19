import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
/// Authentication Providers
///
/// Providers específicos de la feature Authentication.
///
/// La infraestructura Firebase permanece separada en app/providers.
/// ---------------------------------------------------------------------------

final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(firebaseAuthDataSourceProvider),
  );
});

/// Estado global de autenticación.
///
/// El router podrá utilizar este provider para implementar los guards
/// oficiales de GoRouter.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
