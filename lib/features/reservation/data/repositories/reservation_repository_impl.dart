import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../datasources/firebase_reservation_datasource.dart';
import '../models/reservation_model.dart';

/// ---------------------------------------------------------------------------
/// Implementación del Repository de Reservaciones.
/// ---------------------------------------------------------------------------
class ReservationRepositoryImpl implements ReservationRepository {
  ReservationRepositoryImpl({
    required this._dataSource,
  });

  /// DataSource responsable del acceso a Firestore.
  final FirebaseReservationDataSource _dataSource;

  /// -------------------------------------------------------------------------
  /// Obtiene una reservación por su identificador.
  /// -------------------------------------------------------------------------
  @override
  Future<Reservation> getReservation(
      String reservationId,
      ) async {
    _validateReservationId(reservationId);

    // Consulta el documento mediante el DataSource.
    final document = await _dataSource.getReservationDocument(
      reservationId: reservationId,
    );

    // El documento solicitado debe existir.
    if (!document.exists) {
      throw StateError(
        'No existe la reservación solicitada.',
      );
    }

    // Convierte Firestore en el modelo correspondiente.
    final model = ReservationModel.fromFirestore(
      document,
    );

    // El modelo extiende la entidad de dominio.
    return model;
  }

  /// -------------------------------------------------------------------------
  /// Obtiene las reservaciones de un cliente.
  /// -------------------------------------------------------------------------
  @override
  Future<List<Reservation>> getClientReservations(
      String clientId,
      ) async {
    _validateClientId(clientId);

    // Consulta únicamente a través del DataSource.
    final snapshot = await _dataSource.getClientReservationDocuments(
      clientId: clientId,
    );

    // Convierte todos los documentos a entidades de dominio.
    return snapshot.docs
        .map(ReservationModel.fromFirestore)
        .toList();
  }

  /// -------------------------------------------------------------------------
  /// Obtiene las reservaciones de un Coach.
  /// -------------------------------------------------------------------------
  @override
  Future<List<Reservation>> getCoachReservations(
      String coachId,
      ) async {
    _validateCoachId(coachId);

    // Consulta las reservaciones del Coach.
    final snapshot = await _dataSource.getCoachReservationDocuments(
      coachId: coachId,
    );

    // Convierte los documentos Firestore a entidades.
    return snapshot.docs
        .map(ReservationModel.fromFirestore)
        .toList();
  }

  /// -------------------------------------------------------------------------
  /// CK-016.8
  ///
  /// Crea una reservación con estado inicial `pending`.
  ///
  /// Esta operación utiliza específicamente el método
  /// addPendingReservation() del DataSource.
  /// -------------------------------------------------------------------------
  @override
  Future<String> createPendingReservation({
    required String clientId,
    required String coachId,
    required String scheduleId,
    required double amount,
  }) {
    // Validar el identificador del cliente.
    _validateClientId(clientId);

    // Validar el identificador del Coach.
    _validateCoachId(coachId);

    // Validar el identificador del horario.
    _validateScheduleId(scheduleId);

    // El importe no puede ser negativo.
    if (amount < 0) {
      throw ArgumentError(
        'El monto de la reservación no puede ser negativo.',
      );
    }

    // Crear la reservación mediante el DataSource.
    //
    // El DataSource establece automáticamente:
    // status = pending
    // createdAt = FieldValue.serverTimestamp()
    return _dataSource.addPendingReservation(
      clientId: clientId.trim(),
      coachId: coachId.trim(),
      scheduleId: scheduleId.trim(),
      amount: amount,
    );
  }

  @override
  Future<bool> hasActiveReservationForSchedule(String scheduleId) async {
    _validateScheduleId(scheduleId);

    final snapshot = await _dataSource.getReservationsByScheduleId(
      scheduleId: scheduleId,
    );

    return snapshot.docs.any((document) {
      final data = document.data();
      final status = (data['status'] as String? ?? 'pending').trim();
      return status != 'cancelled';
    });
  }

  /// -------------------------------------------------------------------------
  /// Crea una reservación.
  ///
  /// La validación de reglas como:
  /// - horario disponible;
  /// - ausencia de doble reserva;
  /// - estado inicial;
  ///
  /// se implementará posteriormente en CK-016.4.
  /// -------------------------------------------------------------------------
  @override
  Future<String> createReservation({
    required String clientId,
    required String coachId,
    required String scheduleId,
    String? paymentId,
    required String status,
    required double amount,
    required DateTime createdAt,
  }) {
    _validateClientId(clientId);
    _validateCoachId(coachId);
    _validateScheduleId(scheduleId);

    return _dataSource.addReservation(
      clientId: clientId,
      coachId: coachId,
      scheduleId: scheduleId,
      paymentId: paymentId,
      status: status,
      amount: amount,
      createdAt: createdAt,
    );
  }

  /// -------------------------------------------------------------------------
  /// Actualiza el estado de una reservación.
  ///
  /// Las transiciones válidas de estado serán controladas posteriormente
  /// mediante las reglas de negocio de CK-016.4.
  /// -------------------------------------------------------------------------
  @override
  Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
  }) {
    _validateReservationId(reservationId);

    return _dataSource.updateReservationStatus(
      reservationId: reservationId,
      status: status,
    );
  }

  /// -------------------------------------------------------------------------
  /// Asocia un pago a una reservación.
  /// -------------------------------------------------------------------------
  @override
  Future<void> updateReservationPayment({
    required String reservationId,
    required String paymentId,
  }) {
    _validateReservationId(reservationId);

    return _dataSource.updateReservationPayment(
      reservationId: reservationId,
      paymentId: paymentId,
    );
  }

  /// -------------------------------------------------------------------------
  /// Valida el identificador de la reservación.
  /// -------------------------------------------------------------------------
  void _validateReservationId(String reservationId) {
    if (reservationId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador de la reservación es obligatorio.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida el identificador del cliente.
  /// -------------------------------------------------------------------------
  void _validateClientId(String clientId) {
    if (clientId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del cliente es obligatorio.',
      );
    }
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