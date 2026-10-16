class ReservationBusinessRules {
  ReservationBusinessRules._();

  /// Estados oficiales de una reservación.
  static const Set<String> validReservationStatuses = {
    'pending',
    'confirmed',
    'completed',
    'cancelled',
  };

  /// Estados oficiales de un horario.
  static const Set<String> validScheduleStatuses = {
    'available',
    'reserved',
    'blocked',
  };

  /// Estados oficiales de pago definidos por el modelo de datos.
  static const Set<String> validPaymentStatuses = {
    'pending',
    'paid',
    'failed',
    'refunded',
  };

  /// -------------------------------------------------------------------------
  /// Valida que el estado de la reservación sea oficial.
  /// -------------------------------------------------------------------------
  static void validateReservationStatus(
      String status,
      ) {
    final normalizedStatus = status.trim();

    if (!validReservationStatuses.contains(normalizedStatus)) {
      throw ArgumentError(
        'Estado de reservación no válido: $status.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida que el estado del horario sea oficial.
  /// -------------------------------------------------------------------------
  static void validateScheduleStatus(
      String status,
      ) {
    final normalizedStatus = status.trim();

    if (!validScheduleStatuses.contains(normalizedStatus)) {
      throw ArgumentError(
        'Estado de horario no válido: $status.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Una reservación solamente puede realizarse sobre un horario disponible.
  ///
  /// `reserved` y `blocked` no permiten crear una reservación.
  /// -------------------------------------------------------------------------
  static void validateScheduleCanBeReserved(
      String scheduleStatus,
      ) {
    validateScheduleStatus(scheduleStatus);

    if (scheduleStatus.trim() != 'available') {
      throw StateError(
        'El horario seleccionado no está disponible para reservar.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida la regla de no doble reserva.
  ///
  /// El Repository/DataSource deberá determinar si ya existe una reserva
  /// para el horario seleccionado.
  ///
  /// Esta regla no consulta Firestore directamente porque pertenece
  /// a DOMAIN.
  /// -------------------------------------------------------------------------
  static void validateNoDoubleBooking({
    required bool hasExistingReservation,
  }) {
    if (hasExistingReservation) {
      throw StateError(
        'El horario seleccionado ya tiene una reservación.',
      );
    }
  }

  /// Validates a coach's confirmation of a completed session.
  static void validateReservationCanBeCompleted({
    required String status,
  }) {
    validateReservationStatus(status);

    if (status != 'pending' && status != 'confirmed') {
      throw StateError(
        'Solo se pueden completar reservaciones pendientes o confirmadas.',
      );
    }

  }

  /// -------------------------------------------------------------------------
  /// Formatea una hora en formato de 12 horas con AM/PM.
  /// -------------------------------------------------------------------------
  static String formatTime(String time) {
    final normalized = time.trim();
    final parts = normalized.split(':');

    if (parts.length < 2) {
      return normalized;
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  /// -------------------------------------------------------------------------
  /// Formatea un rango horario con AM/PM.
  /// -------------------------------------------------------------------------
  static String formatTimeRange(String startTime, String endTime) {
    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }

  /// -------------------------------------------------------------------------
  /// Valida el importe de la reservación.
  /// -------------------------------------------------------------------------
  static void validateAmount(
      double amount,
      ) {
    if (amount < 0) {
      throw ArgumentError(
        'El importe de la reservación no puede ser negativo.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida que el estado de pago sea oficial.
  /// -------------------------------------------------------------------------
  static void validatePaymentStatus(
      String paymentStatus,
      ) {
    final normalizedStatus = paymentStatus.trim();

    if (!validPaymentStatuses.contains(normalizedStatus)) {
      throw ArgumentError(
        'Estado de pago no válido: $paymentStatus.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Una reservación confirmada requiere un pago exitoso.
  ///
  /// La especificación oficial define:
  /// - Reserva confirmed.
  /// - Pago paid.
  ///
  /// Por eso no basta con que exista paymentId:
  /// el estado del pago debe ser `paid`.
  /// -------------------------------------------------------------------------
  static void validateConfirmedReservationPayment({
    required String reservationStatus,
    required String paymentStatus,
  }) {
    validateReservationStatus(reservationStatus);
    validatePaymentStatus(paymentStatus);

    if (reservationStatus.trim() == 'confirmed' &&
        paymentStatus.trim() != 'paid') {
      throw StateError(
        'Una reservación confirmada requiere un pago exitoso.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida los datos básicos necesarios para una reservación.
  ///
  /// Esta validación no determina disponibilidad ni doble reserva;
  /// esas reglas tienen métodos independientes.
  /// -------------------------------------------------------------------------
  static void validateReservationData({
    required String clientId,
    required String coachId,
    required String scheduleId,
    required String status,
    required double amount,
  }) {
    if (clientId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del cliente es obligatorio.',
      );
    }

    if (coachId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del Coach es obligatorio.',
      );
    }

    if (scheduleId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del horario es obligatorio.',
      );
    }

    validateReservationStatus(status);
    validateAmount(amount);
  }
}