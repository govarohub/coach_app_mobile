import '../entities/reservation.dart';

/// ---------------------------------------------------------------------------
/// Repository de Reservaciones.
///
/// Define las operaciones que el resto de la aplicación puede utilizar
/// para trabajar con reservaciones.
///
/// IMPORTANTE:
/// - No contiene código de Firestore.
/// - No contiene código de Flutter.
/// - No contiene lógica de presentación.
/// - No implementa las reglas completas de negocio.
/// ---------------------------------------------------------------------------
abstract interface class ReservationRepository {
  /// Obtiene una reservación mediante su identificador.
  Future<Reservation> getReservation(String reservationId);

  /// Obtiene las reservaciones realizadas por un cliente.
  Future<List<Reservation>> getClientReservations(
      String clientId,
      );

  /// Obtiene las reservaciones pertenecientes a un Coach.
  Future<List<Reservation>> getCoachReservations(
      String coachId,
      );

  /// Crea una nueva reservación.
  Future<String> createReservation({
    required String clientId,
    required String coachId,
    required String scheduleId,
    String? paymentId,
    required String status,
    required double amount,
    required DateTime createdAt,
  });

  /// -------------------------------------------------------------------------
  /// CK-016.8
  ///
  /// Crea una reservación con estado inicial `pending`.
  ///
  /// Esta operación se utiliza para el flujo inicial de creación de una
  /// reservación antes de completar las etapas posteriores del proceso.
  /// -------------------------------------------------------------------------
  Future<String> createPendingReservation({
    required String clientId,
    required String coachId,
    required String scheduleId,
    required double amount,
  });

  /// Actualiza el estado de una reservación.
  Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
  });

  /// Asocia un pago a una reservación.
  Future<void> updateReservationPayment({
    required String reservationId,
    required String paymentId,
  });
}