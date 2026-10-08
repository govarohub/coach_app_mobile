/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo:
/// lib/features/reservation/domain/entities/reservation.dart
///
/// CK-016.1
/// CK-017.10
///
/// Entidad de dominio de una reservación.
///
/// Responsabilidades:
/// - Representar una reservación dentro del dominio.
/// - Definir los estados oficiales de una reservación.
/// - Validar que el estado recibido pertenezca al ciclo de vida oficial.
///
/// IMPORTANTE:
/// - No contiene código de Firebase.
/// - No contiene código de UI.
/// - Las reglas de estado pertenecen al dominio.
/// ---------------------------------------------------------------------------
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
  /// Estados definidos por las reglas de negocio:
  /// - pending
  /// - confirmed
  /// - completed
  /// - cancelled
  final String status;

  /// Importe de la reservación.
  final double amount;

  /// Fecha de creación de la reservación.
  final DateTime createdAt;

  /// -------------------------------------------------------------------------
  /// CK-017.10
  ///
  /// Estados oficiales de una reservación.
  ///
  /// Se mantienen exactamente los estados definidos en las reglas de negocio.
  /// -------------------------------------------------------------------------
  static const Set<String> officialStatuses = {
    'pending',
    'confirmed',
    'completed',
    'cancelled',
  };

  /// -------------------------------------------------------------------------
  /// CK-017.10
  ///
  /// Valida un estado antes de utilizarlo en una operación de dominio.
  ///
  /// Esta validación NO define nuevas transiciones de negocio.
  /// Únicamente garantiza que el estado pertenezca al catálogo oficial.
  /// -------------------------------------------------------------------------
  static void validateStatus(String value) {
    final normalizedStatus = value.trim();

    if (!officialStatuses.contains(normalizedStatus)) {
      throw StateError(
        'El estado de la reservación no es válido: $value.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// CK-017.10
  ///
  /// Valida el estado actual de esta reservación.
  ///
  /// Se utiliza cuando una reservación es obtenida desde el Repository para
  /// evitar que información con estados no oficiales avance hacia las capas
  /// superiores.
  /// -------------------------------------------------------------------------
  void validateOfficialStatus() {
    validateStatus(status);
  }
}