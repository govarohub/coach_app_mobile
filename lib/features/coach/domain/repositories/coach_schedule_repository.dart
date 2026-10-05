import '../entities/coach_schedule.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: coach_schedule_repository.dart
///
/// Contrato de acceso a los horarios del Coach.
///
/// El dominio define las operaciones disponibles sin conocer los detalles
/// de Firebase o Firestore.
/// ---------------------------------------------------------------------------

abstract interface class CoachScheduleRepository {
  /// -------------------------------------------------------------------------
  /// Obtiene todos los horarios de un Coach.
  ///
  /// Incluye:
  /// - available
  /// - reserved
  /// - blocked
  ///
  /// Se utiliza principalmente para la administración de agenda del Coach.
  /// -------------------------------------------------------------------------
  Future<List<CoachSchedule>> getSchedules(String coachId);

  /// -------------------------------------------------------------------------
  /// Obtiene únicamente los horarios disponibles para reservación.
  ///
  /// Solamente devuelve horarios cuyo estado sea:
  ///
  /// `available`
  ///
  /// Los estados `reserved` y `blocked` no forman parte del resultado.
  /// -------------------------------------------------------------------------
  Future<List<CoachSchedule>> getAvailableSchedules(String coachId);

  /// -------------------------------------------------------------------------
  /// Obtiene un horario específico.
  /// -------------------------------------------------------------------------
  Future<CoachSchedule> getSchedule(String scheduleId);

  /// -------------------------------------------------------------------------
  /// Crea un nuevo horario.
  /// -------------------------------------------------------------------------
  Future<String> createSchedule({
    required String coachId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String status,
  });

  /// -------------------------------------------------------------------------
  /// Actualiza un horario existente.
  /// -------------------------------------------------------------------------
  Future<void> updateSchedule({
    required String scheduleId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String status,
  });

  /// -------------------------------------------------------------------------
  /// Actualiza únicamente el estado de un horario.
  /// -------------------------------------------------------------------------
  Future<void> updateScheduleStatus({
    required String scheduleId,
    required String status,
  });
}