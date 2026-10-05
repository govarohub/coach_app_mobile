import 'package:cloud_firestore/cloud_firestore.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// DataSource Firebase para la colección `schedules`.
///
/// Responsabilidad:
/// - Consultar horarios de un Coach.
/// - Consultar horarios disponibles de un Coach.
/// - Consultar un horario específico.
/// - Crear un horario.
/// - Actualizar un horario.
/// - Actualizar el estado de un horario.
///
/// Este archivo únicamente se encarga del acceso a Firestore.
/// La lógica de negocio se implementará en las capas superiores.
/// ---------------------------------------------------------------------------

class FirebaseCoachScheduleDataSource {
  FirebaseCoachScheduleDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Instancia de Firestore utilizada para acceder a `schedules`.
  final FirebaseFirestore _firestore;

  /// Referencia a la colección oficial de horarios.
  CollectionReference<Map<String, dynamic>> get _schedulesCollection {
    return _firestore.collection('schedules');
  }

  /// -------------------------------------------------------------------------
  /// Obtiene todos los horarios pertenecientes a un Coach.
  ///
  /// Incluye todos los estados oficiales:
  /// - available
  /// - reserved
  /// - blocked
  ///
  /// Este método se mantiene para la administración de horarios del Coach
  /// correspondiente a CK-015.
  /// -------------------------------------------------------------------------
  Future<QuerySnapshot<Map<String, dynamic>>> getScheduleDocuments({
    required String coachId,
  }) {
    _validateCoachId(coachId);

    return _schedulesCollection
        .where('coachId', isEqualTo: coachId)
        .get();
  }

  /// -------------------------------------------------------------------------
  /// Obtiene únicamente los horarios disponibles para reservación.
  ///
  /// Un horario solamente puede aparecer en el flujo de reservación cuando
  /// su estado sea exactamente `available`.
  ///
  /// Los horarios `reserved` y `blocked` quedan fuera de esta consulta.
  /// -------------------------------------------------------------------------
  Future<QuerySnapshot<Map<String, dynamic>>>
  getAvailableScheduleDocuments({
    required String coachId,
  }) {
    _validateCoachId(coachId);

    return _schedulesCollection
        .where('coachId', isEqualTo: coachId)
        .where('status', isEqualTo: 'available')
        .get();
  }

  /// -------------------------------------------------------------------------
  /// Obtiene un horario específico.
  ///
  /// schedules/{scheduleId}
  /// -------------------------------------------------------------------------
  Future<DocumentSnapshot<Map<String, dynamic>>> getScheduleDocument({
    required String scheduleId,
  }) {
    _validateScheduleId(scheduleId);

    return _schedulesCollection.doc(scheduleId).get();
  }

  /// -------------------------------------------------------------------------
  /// Crea un nuevo horario.
  ///
  /// El identificador generado por Firestore se utiliza también como
  /// `scheduleId`, manteniendo ambos identificadores sincronizados.
  ///
  /// Campos oficiales utilizados:
  /// - scheduleId
  /// - coachId
  /// - date
  /// - startTime
  /// - endTime
  /// - status
  /// -------------------------------------------------------------------------
  Future<String> addSchedule({
    required String coachId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String status,
  }) async {
    _validateCoachId(coachId);
    _validateTime(startTime, fieldName: 'startTime');
    _validateTime(endTime, fieldName: 'endTime');
    _validateStatus(status);

    // Genera el identificador del nuevo horario.
    final document = _schedulesCollection.doc();

    // Guarda únicamente los campos definidos oficialmente.
    await document.set({
      'scheduleId': document.id,
      'coachId': coachId.trim(),
      'date': Timestamp.fromDate(date),
      'startTime': startTime.trim(),
      'endTime': endTime.trim(),
      'status': status.trim(),
    });

    // Devuelve el identificador generado.
    return document.id;
  }

  /// -------------------------------------------------------------------------
  /// Actualiza la información de un horario existente.
  ///
  /// No modifica `scheduleId` ni `coachId`.
  /// -------------------------------------------------------------------------
  Future<void> updateSchedule({
    required String scheduleId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String status,
  }) {
    _validateScheduleId(scheduleId);
    _validateTime(startTime, fieldName: 'startTime');
    _validateTime(endTime, fieldName: 'endTime');
    _validateStatus(status);

    return _schedulesCollection.doc(scheduleId.trim()).update({
      'date': Timestamp.fromDate(date),
      'startTime': startTime.trim(),
      'endTime': endTime.trim(),
      'status': status.trim(),
    });
  }

  /// -------------------------------------------------------------------------
  /// Actualiza únicamente el estado de un horario.
  ///
  /// Estados oficiales:
  /// - available
  /// - reserved
  /// - blocked
  ///
  /// La validación de cuándo puede realizarse cada transición
  /// corresponderá a la capa de dominio.
  /// -------------------------------------------------------------------------
  Future<void> updateScheduleStatus({
    required String scheduleId,
    required String status,
  }) {
    _validateScheduleId(scheduleId);
    _validateStatus(status);

    return _schedulesCollection.doc(scheduleId.trim()).update({
      'status': status.trim(),
    });
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

  /// -------------------------------------------------------------------------
  /// Valida que la hora no esté vacía.
  ///
  /// La especificación define `startTime` y `endTime` como String.
  /// La validación de formato específico se realizará posteriormente
  /// en la capa correspondiente.
  /// -------------------------------------------------------------------------
  void _validateTime(
      String value, {
        required String fieldName,
      }) {
    if (value.trim().isEmpty) {
      throw ArgumentError(
        'El campo $fieldName es obligatorio.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida los estados oficiales de `schedules`.
  /// -------------------------------------------------------------------------
  void _validateStatus(String status) {
    const validStatuses = {
      'available',
      'reserved',
      'blocked',
    };

    if (!validStatuses.contains(status.trim())) {
      throw ArgumentError(
        'Estado de horario no válido: $status.',
      );
    }
  }
}