import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firebase_coach_schedule_datasource.dart';
import '../../data/repositories/coach_schedule_repository_impl.dart';
import '../../domain/entities/coach_schedule.dart';
import '../../domain/repositories/coach_schedule_repository.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo:
/// lib/features/coach/presentation/pages/coach_schedule_provider.dart
///
/// CK-015.4
/// CK-015.11
///
/// Providers y Controller para la gestión de horarios del Coach.
///
/// Responsabilidades:
/// - Conectar DataSource y Repository.
/// - Consultar los horarios de un Coach.
/// - Consultar únicamente horarios disponibles.
/// - Centralizar las operaciones de escritura.
/// - Aplicar las reglas de negocio correspondientes al cambio manual
///   de disponibilidad.
/// - Invalidar las consultas después de una modificación.
///
/// Este archivo no contiene código de UI.
/// ---------------------------------------------------------------------------

/// ---------------------------------------------------------------------------
/// DataSource de horarios.
/// ---------------------------------------------------------------------------

final firebaseCoachScheduleDataSourceProvider =
Provider<FirebaseCoachScheduleDataSource>((ref) {
  return FirebaseCoachScheduleDataSource();
});

/// ---------------------------------------------------------------------------
/// Repository de horarios.
///
/// La presentación utiliza el contrato de dominio y no accede
/// directamente al DataSource.
/// ---------------------------------------------------------------------------

final coachScheduleRepositoryProvider =
Provider<CoachScheduleRepository>((ref) {
  final dataSource = ref.watch(
    firebaseCoachScheduleDataSourceProvider,
  );

  return CoachScheduleRepositoryImpl(
    dataSource: dataSource,
  );
});

/// ---------------------------------------------------------------------------
/// Consulta todos los horarios de un Coach.
///
/// Se utiliza Family porque la información depende del coachId.
///
/// Incluye todos los estados:
/// - available
/// - reserved
/// - blocked
///
/// Este provider se mantiene para la administración de agenda del Coach.
/// ---------------------------------------------------------------------------

final coachSchedulesProvider =
FutureProvider.family<List<CoachSchedule>, String>(
      (ref, coachId) async {
    final repository = ref.watch(
      coachScheduleRepositoryProvider,
    );

    return repository.getSchedules(coachId);
  },
);

/// ---------------------------------------------------------------------------
/// Consulta únicamente los horarios disponibles de un Coach.
///
/// Solamente devuelve horarios cuyo estado sea:
///
/// available
///
/// Los horarios:
/// - reserved
/// - blocked
///
/// quedan excluidos del resultado.
///
/// Este provider es utilizado por el flujo de reservación.
/// ---------------------------------------------------------------------------

final coachAvailableSchedulesProvider =
FutureProvider.family<List<CoachSchedule>, String>(
      (ref, coachId) async {
    final repository = ref.watch(
      coachScheduleRepositoryProvider,
    );

    return repository.getAvailableSchedules(coachId);
  },
);

/// ---------------------------------------------------------------------------
/// Controller de horarios.
///
/// Centraliza las operaciones de escritura y mantiene actualizadas
/// las consultas de horarios después de cada modificación.
/// ---------------------------------------------------------------------------

class CoachScheduleController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No requiere una carga inicial.
  }

  /// -------------------------------------------------------------------------
  /// Crea un nuevo horario.
  /// -------------------------------------------------------------------------
  Future<void> createSchedule({
    required String coachId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String status,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(
        coachScheduleRepositoryProvider,
      );

      await repository.createSchedule(
        coachId: coachId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        status: status,
      );

      // Recarga la agenda completa del Coach.
      ref.invalidate(
        coachSchedulesProvider(coachId),
      );

      // Recarga también la consulta utilizada por reservaciones.
      ref.invalidate(
        coachAvailableSchedulesProvider(coachId),
      );
    });
  }

  /// -------------------------------------------------------------------------
  /// Actualiza un horario existente.
  ///
  /// Esta operación conserva su comportamiento original.
  ///
  /// No se agregan aquí reglas de transición de estados porque esta operación
  /// también puede utilizarse para actualizar otros datos del horario.
  /// -------------------------------------------------------------------------
  Future<void> updateSchedule({
    required String coachId,
    required String scheduleId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String status,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(
        coachScheduleRepositoryProvider,
      );

      await repository.updateSchedule(
        scheduleId: scheduleId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        status: status,
      );

      // Recarga la agenda completa del Coach.
      ref.invalidate(
        coachSchedulesProvider(coachId),
      );

      // Recarga la consulta de horarios disponibles.
      ref.invalidate(
        coachAvailableSchedulesProvider(coachId),
      );
    });
  }

  /// -------------------------------------------------------------------------
  /// CK-015.11
  ///
  /// Bloquea o desbloquea manualmente un horario.
  ///
  /// Esta operación es independiente del cambio:
  ///
  /// available -> reserved
  ///
  /// utilizado por el flujo de reservación.
  ///
  /// Para evitar mezclar ambas reglas, aquí se obtiene primero el horario
  /// actual y se valida la transición mediante la entidad de dominio.
  ///
  /// Transiciones permitidas:
  ///
  /// available -> blocked
  /// blocked   -> available
  ///
  /// Transiciones rechazadas:
  ///
  /// reserved -> blocked
  /// reserved -> available
  ///
  /// La persistencia continúa realizándose mediante:
  ///
  /// Presentation
  ///     ↓
  /// Controller
  ///     ↓
  /// Repository
  ///     ↓
  /// DataSource
  ///     ↓
  /// Firebase
  /// -------------------------------------------------------------------------
  Future<void> updateManualScheduleStatus({
    required String coachId,
    required String scheduleId,
    required String newStatus,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(
        coachScheduleRepositoryProvider,
      );

      /// ---------------------------------------------------------------------
      /// Obtiene el horario actual desde el Repository.
      ///
      /// Esto evita confiar únicamente en el estado mostrado por la UI.
      /// ---------------------------------------------------------------------
      final schedule = await repository.getSchedule(
        scheduleId,
      );

      /// ---------------------------------------------------------------------
      /// CK-015.11
      ///
      /// La regla de transición se valida en Domain.
      /// ---------------------------------------------------------------------
      schedule.validateManualStatusChange(
        newStatus,
      );

      /// ---------------------------------------------------------------------
      /// Si la transición es válida, se persiste el nuevo estado.
      /// ---------------------------------------------------------------------
      await repository.updateScheduleStatus(
        scheduleId: scheduleId,
        status: newStatus,
      );

      /// ---------------------------------------------------------------------
      /// Actualiza la agenda completa del Coach.
      /// ---------------------------------------------------------------------
      ref.invalidate(
        coachSchedulesProvider(coachId),
      );

      /// ---------------------------------------------------------------------
      /// Actualiza la consulta de horarios disponibles.
      ///
      /// available -> blocked:
      /// el horario deja de estar disponible para reservar.
      ///
      /// blocked -> available:
      /// el horario vuelve a estar disponible para reservar.
      /// ---------------------------------------------------------------------
      ref.invalidate(
        coachAvailableSchedulesProvider(coachId),
      );
    });
  }

  /// -------------------------------------------------------------------------
  /// Cambia únicamente el estado de un horario.
  ///
  /// IMPORTANTE:
  ///
  /// Este método se conserva porque el flujo de reservación necesita realizar
  /// la transición:
  ///
  /// available -> reserved
  ///
  /// No se modifica su comportamiento para no romper CK-016.
  ///
  /// El bloqueo/desbloqueo manual del Coach debe utilizar:
  ///
  /// updateManualScheduleStatus()
  ///
  /// para aplicar las reglas de CK-015.11.
  /// -------------------------------------------------------------------------
  Future<void> updateScheduleStatus({
    required String coachId,
    required String scheduleId,
    required String status,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(
        coachScheduleRepositoryProvider,
      );

      await repository.updateScheduleStatus(
        scheduleId: scheduleId,
        status: status,
      );

      // Recarga la agenda completa después del cambio de estado.
      ref.invalidate(
        coachSchedulesProvider(coachId),
      );

      // Recarga también los horarios disponibles.
      //
      // available -> blocked
      // elimina el horario de la consulta de reservación.
      //
      // blocked -> available
      // vuelve a incorporarlo.
      //
      // available -> reserved
      // también lo elimina de la consulta de horarios disponibles.
      ref.invalidate(
        coachAvailableSchedulesProvider(coachId),
      );
    });
  }
}

/// ---------------------------------------------------------------------------
/// Provider del Controller de horarios.
/// ---------------------------------------------------------------------------

final coachScheduleControllerProvider =
AsyncNotifierProvider<CoachScheduleController, void>(
  CoachScheduleController.new,
);