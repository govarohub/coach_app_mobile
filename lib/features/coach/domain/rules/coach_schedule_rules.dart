abstract final class CoachScheduleRules {
  CoachScheduleRules._();

  /// Estados oficiales de la colección `schedules`.
  static const Set<String> validStatuses = {
    'available',
    'reserved',
    'blocked',
  };

  /// Valida el identificador del Coach.
  static void validateCoachId(String coachId) {
    if (coachId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del Coach es obligatorio.',
      );
    }
  }

  /// Valida el identificador del horario.
  static void validateScheduleId(String scheduleId) {
    if (scheduleId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del horario es obligatorio.',
      );
    }
  }

  /// Valida una hora utilizando el formato oficial HH:mm.
  static void validateTime(
      String value, {
        required String fieldName,
      }) {
    final normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      throw ArgumentError(
        'El campo $fieldName es obligatorio.',
      );
    }

    final match = RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d)$',
    ).firstMatch(normalizedValue);

    if (match == null) {
      throw ArgumentError(
        'El campo $fieldName debe utilizar el formato HH:mm.',
      );
    }
  }

  /// Valida que la hora de finalización sea posterior al inicio.
  static void validateTimeRange({
    required String startTime,
    required String endTime,
  }) {
    validateTime(
      startTime,
      fieldName: 'startTime',
    );

    validateTime(
      endTime,
      fieldName: 'endTime',
    );

    final start = _timeToMinutes(startTime);
    final end = _timeToMinutes(endTime);

    if (end <= start) {
      throw ArgumentError(
        'La hora de finalización debe ser posterior '
            'a la hora de inicio.',
      );
    }
  }

  /// Valida un estado oficial de horario.
  static void validateStatus(String status) {
    final normalizedStatus = status.trim();

    if (!validStatuses.contains(normalizedStatus)) {
      throw ArgumentError(
        'Estado de horario no válido: $status.',
      );
    }
  }

  /// Ejecuta las validaciones completas de un horario.
  static void validateSchedule({
    required String coachId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String status,
  }) {
    validateCoachId(coachId);
    validateTimeRange(
      startTime: startTime,
      endTime: endTime,
    );
    validateStatus(status);
  }

  /// Convierte una hora HH:mm en minutos desde medianoche.
  static int _timeToMinutes(String value) {
    final parts = value.trim().split(':');

    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);

    return (hours * 60) + minutes;
  }
}