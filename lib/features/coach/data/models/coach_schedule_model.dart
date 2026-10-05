import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/coach_schedule.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: coach_schedule_model.dart
///
/// CK-015.1
///
/// Modelo de persistencia para la colección Firestore `schedules`.
///
/// Este modelo transforma los datos de Firestore en la entidad de dominio
/// CoachSchedule.
/// ---------------------------------------------------------------------------

class CoachScheduleModel extends CoachSchedule {
  const CoachScheduleModel({
    required super.scheduleId,
    required super.coachId,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.status,
  });

  /// Construye el modelo a partir de un documento Firestore.
  ///
  /// Colección oficial:
  /// schedules
  ///
  /// Campos oficiales:
  /// scheduleId
  /// coachId
  /// date
  /// startTime
  /// endTime
  /// status
  factory CoachScheduleModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data();

    if (data == null) {
      throw StateError(
        'El horario ${document.id} no contiene información.',
      );
    }

    // El identificador oficial se obtiene del campo scheduleId.
    // Si el documento no lo contiene, se utiliza el ID del documento
    // como respaldo para evitar perder la referencia del horario.
    final scheduleId = data['scheduleId'] as String? ?? document.id;

    final coachId = data['coachId'] as String? ?? '';

    // El campo date está definido oficialmente como Timestamp.
    final timestamp = data['date'];

    if (timestamp is! Timestamp) {
      throw StateError(
        'El horario $scheduleId no contiene una fecha válida.',
      );
    }

    final startTime = data['startTime'] as String? ?? '';
    final endTime = data['endTime'] as String? ?? '';
    final status = data['status'] as String? ?? '';

    // Validamos los campos obligatorios antes de crear la entidad.
    if (scheduleId.trim().isEmpty) {
      throw StateError(
        'El horario no contiene un scheduleId válido.',
      );
    }

    if (coachId.trim().isEmpty) {
      throw StateError(
        'El horario $scheduleId no contiene un coachId válido.',
      );
    }

    if (startTime.trim().isEmpty) {
      throw StateError(
        'El horario $scheduleId no contiene una hora de inicio válida.',
      );
    }

    if (endTime.trim().isEmpty) {
      throw StateError(
        'El horario $scheduleId no contiene una hora de finalización válida.',
      );
    }

    if (!_isValidStatus(status)) {
      throw StateError(
        'El horario $scheduleId contiene un estado no válido: $status.',
      );
    }

    return CoachScheduleModel(
      scheduleId: scheduleId.trim(),
      coachId: coachId.trim(),
      date: timestamp.toDate(),
      startTime: startTime.trim(),
      endTime: endTime.trim(),
      status: status.trim(),
    );
  }

  /// Convierte el modelo al formato de persistencia de Firestore.
  ///
  /// Se utilizan únicamente los campos definidos oficialmente para
  /// la colección `schedules`.
  Map<String, dynamic> toFirestore() {
    return {
      'scheduleId': scheduleId,
      'coachId': coachId,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
    };
  }

  /// Valida los estados oficiales definidos para un horario.
  static bool _isValidStatus(String status) {
    return status == 'available' ||
        status == 'reserved' ||
        status == 'blocked';
  }
}