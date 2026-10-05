class Reservation {
  const Reservation({
    required this.reservationId,
    required this.clientId,
    required this.coachId,
    required this.scheduleId,
    this.paymentId,
    required this.status,
    required this.amount,
    required this.createdAt,
  });

  /// Identificador único de la reservación.
  final String reservationId;

  /// UID del cliente que realiza la reservación.
  final String clientId;

  /// UID del Coach propietario del horario.
  final String coachId;

  /// Identificador del horario que se reserva.
  final String scheduleId;

  /// Identificador del pago asociado.
  ///
  /// Es opcional porque la reserva puede iniciar como `pending`.
  final String? paymentId;

  /// Estado oficial de la reservación.
  ///
  /// Valores:
  /// pending, confirmed, completed, cancelled.
  final String status;

  /// Importe de la reservación.
  final double amount;

  /// Fecha de creación de la reservación.
  final DateTime createdAt;
}