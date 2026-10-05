class CoachSchedule {
  const CoachSchedule({
    required this.scheduleId,
    required this.coachId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  /// Identificador único del horario.
  final String scheduleId;

  /// Identificador del Coach propietario del horario.
  final String coachId;

  /// Fecha correspondiente al horario.
  final DateTime date;

  /// Hora de inicio en formato String definido por Firestore.
  final String startTime;

  /// Hora de finalización en formato String definido por Firestore.
  final String endTime;

  /// Estado oficial del horario.
  ///
  /// Valores definidos por la especificación:
  /// - available
  /// - reserved
  /// - blocked
  final String status;

  /// -------------------------------------------------------------------------
  /// CK-015.11
  ///
  /// Valida si el horario puede cambiar de estado mediante una acción
  /// manual del Coach.
  ///
  /// Reglas oficiales aplicadas:
  ///
  /// available -> blocked
  /// blocked   -> available
  ///
  /// No se permite modificar manualmente un horario reservado:
  ///
  /// reserved -> blocked
  /// reserved -> available
  ///
  /// IMPORTANTE:
  /// Esta validación corresponde exclusivamente al bloqueo/desbloqueo
  /// manual realizado por el Coach.
  ///
  /// El cambio:
  ///
  /// available -> reserved
  ///
  /// pertenece al flujo de reservación y NO debe pasar por esta validación,
  /// ya que es una operación diferente.
  /// -------------------------------------------------------------------------
  void validateManualStatusChange(String newStatus) {
    // Validamos únicamente los estados oficiales.
    const validStatuses = {
      'available',
      'reserved',
      'blocked',
    };

    if (!validStatuses.contains(status)) {
      throw StateError(
        'El horario contiene un estado actual no válido: $status.',
      );
    }

    if (!validStatuses.contains(newStatus)) {
      throw StateError(
        'El nuevo estado del horario no es válido: $newStatus.',
      );
    }

    /// -----------------------------------------------------------------------
    /// Un horario reservado no puede ser bloqueado ni desbloqueado
    /// manualmente por el Coach.
    /// -----------------------------------------------------------------------
    if (status == 'reserved') {
      throw StateError(
        'Un horario reservado no puede bloquearse ni desbloquearse.',
      );
    }

    /// -----------------------------------------------------------------------
    /// La operación manual únicamente permite:
    ///
    /// available -> blocked
    /// blocked   -> available
    /// -----------------------------------------------------------------------
    final isValidManualTransition =
        (status == 'available' && newStatus == 'blocked') ||
            (status == 'blocked' && newStatus == 'available');

    if (!isValidManualTransition) {
      throw StateError(
        'La transición manual de $status a $newStatus no está permitida.',
      );
    }
  }
}