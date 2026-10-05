import '../../domain/entities/coach_schedule.dart';
import '../../domain/repositories/coach_schedule_repository.dart';
import '../datasources/firebase_coach_schedule_datasource.dart';
import '../models/coach_schedule_model.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: coach_schedule_repository_impl.dart
///
/// CK-015.3
///
/// Implementación concreta del Repository de horarios.
/// ---------------------------------------------------------------------------

class CoachScheduleRepositoryImpl
    implements CoachScheduleRepository {
  CoachScheduleRepositoryImpl({
    required this._dataSource,
  });

  /// DataSource utilizado para acceder a Firestore.
  final FirebaseCoachScheduleDataSource _dataSource;

  /// -------------------------------------------------------------------------
  /// Obtiene todos los horarios de un Coach.
  ///
  /// Incluye todos los estados:
  /// - available
  /// - reserved
  /// - blocked
  ///
  /// Se mantiene sin cambios funcionales para CK-015.
  /// -------------------------------------------------------------------------
  @override
  Future<List<CoachSchedule>> getSchedules(
      String coachId,
      ) async {
    _validateCoachId(coachId);

    // Consulta todos los horarios del Coach.
    final snapshot = await _dataSource.getScheduleDocuments(
      coachId: coachId,
    );

    // Convierte los documentos Firestore en entidades de dominio.
    return snapshot.docs
        .map(CoachScheduleModel.fromFirestore)
        .toList();
  }

  /// -------------------------------------------------------------------------
  /// Obtiene únicamente los horarios disponibles para reservación.
  ///
  /// Solamente devuelve horarios cuyo estado sea `available`.
  ///
  /// Los horarios `reserved` y `blocked` quedan excluidos.
  /// -------------------------------------------------------------------------
  @override
  Future<List<CoachSchedule>> getAvailableSchedules(
      String coachId,
      ) async {
    _validateCoachId(coachId);

    // Consulta únicamente horarios disponibles del Coach.
    final snapshot =
    await _dataSource.getAvailableScheduleDocuments(
      coachId: coachId,
    );

    // Convierte los documentos Firestore en entidades de dominio.
    return snapshot.docs
        .map(CoachScheduleModel.fromFirestore)
        .toList();
  }

  /// -------------------------------------------------------------------------
  /// Obtiene un horario específico.
  /// -------------------------------------------------------------------------
  @override
  Future<CoachSchedule> getSchedule(
      String scheduleId,
      ) async {
    _validateScheduleId(scheduleId);

    // Consulta schedules/{scheduleId}.
    final document = await _dataSource.getScheduleDocument(
      scheduleId: scheduleId,
    );

    // El horario debe existir.
    if (!document.exists) {
      throw StateError(
        'No existe el horario solicitado.',
      );
    }

    // Convierte Firestore en la entidad de dominio.
    return CoachScheduleModel.fromFirestore(document);
  }

  /// -------------------------------------------------------------------------
  /// Crea un nuevo horario.
  /// -------------------------------------------------------------------------
  @override
  Future<String> createSchedule({
    required String coachId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String status,
  }) {
    _validateCoachId(coachId);

    // Delega la persistencia al DataSource.
    return _dataSource.addSchedule(
      coachId: coachId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: status,
    );
  }

  /// -------------------------------------------------------------------------
  /// Actualiza un horario existente.
  /// -------------------------------------------------------------------------
  @override
  Future<void> updateSchedule({
    required String scheduleId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String status,
  }) {
    _validateScheduleId(scheduleId);

    // Delega la actualización al DataSource.
    return _dataSource.updateSchedule(
      scheduleId: scheduleId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: status,
    );
  }

  /// -------------------------------------------------------------------------
  /// Actualiza únicamente el estado del horario.
  /// -------------------------------------------------------------------------
  @override
  Future<void> updateScheduleStatus({
    required String scheduleId,
    required String status,
  }) {
    _validateScheduleId(scheduleId);

    // Delega el cambio de estado al DataSource.
    return _dataSource.updateScheduleStatus(
      scheduleId: scheduleId,
      status: status,
    );
  }

  /// -------------------------------------------------------------------------
  /// Valida el identificador del Coach.
  /// -------------------------------------------------------------------------
  void _validateCoachId(String coachId) {
    if (coachId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del Coach es obligatorio.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida el identificador del horario.
  /// -------------------------------------------------------------------------
  void _validateScheduleId(String scheduleId) {
    if (scheduleId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del horario es obligatorio.',
      );
    }
  }
}