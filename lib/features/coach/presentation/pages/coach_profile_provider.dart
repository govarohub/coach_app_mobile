import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firebase_coach_datasource.dart';
import '../../data/repositories/coach_profile_repository_impl.dart';
import '../../domain/entities/coach_profile.dart';
import '../../domain/repositories/coach_profile_repository.dart';



/// Provider del DataSource de Coach.
///
/// Mantiene la creación de FirebaseCoachDataSource en un único punto.
final firebaseCoachDataSourceProvider = Provider<FirebaseCoachDataSource>(
      (ref) {
    return FirebaseCoachDataSource();
  },
);

/// Provider del Repository del perfil profesional.
final coachProfileRepositoryProvider = Provider<CoachProfileRepository>(
      (ref) {
    final dataSource = ref.watch(firebaseCoachDataSourceProvider);

    return CoachProfileRepositoryImpl(
      dataSource: dataSource,
    );
  },
);

/// Provider que consulta el perfil profesional mediante el coachId.
///
/// Se utiliza como Family porque el perfil depende del identificador
/// del Coach que se desea consultar.
final coachProfileProvider =
FutureProvider.family<CoachProfile, String>((ref, coachId) async {
  final repository = ref.watch(coachProfileRepositoryProvider);

  return repository.getProfile(coachId);
});

/// Controller encargado de actualizar el perfil profesional.
class CoachProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No requiere una carga inicial.
  }

  /// Actualiza la información profesional del coach.
  Future<void> updateProfile({
    required String coachId,
    required List<String> specialties,
    required int experienceYears,
    required double hourlyRate,
    required String? bio,
    required CoachLocation? location,
    required bool available,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(coachProfileRepositoryProvider);

      await repository.updateProfile(
        coachId: coachId,
        specialties: specialties,
        experienceYears: experienceYears,
        hourlyRate: hourlyRate,
        bio: bio,
        location: location,
        available: available,
      );

      // Fuerza la recarga del perfil después de guardar.
      ref.invalidate(coachProfileProvider(coachId));
    });
  }
}

/// Provider del controller del perfil profesional.
final coachProfileControllerProvider =
AsyncNotifierProvider<CoachProfileController, void>(
  CoachProfileController.new,
);