import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseReservationDataSource {
  FirebaseReservationDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Instancia de Firestore utilizada por este DataSource.
  final FirebaseFirestore _firestore;

  /// Referencia a la colección oficial de reservaciones.
  CollectionReference<Map<String, dynamic>>
  get _reservationsCollection {
    return _firestore.collection('reservations');
  }

  /// ---------------------------------------------------------------------------
  /// CK-016.8
  ///
  /// Crea una nueva reservación con estado inicial `pending`.
  ///
  /// Este método se utiliza específicamente para la creación inicial de una
  /// reservación desde el flujo de CK-016.8.
  ///
  /// El paymentId no se agrega porque la reservación se encuentra pendiente
  /// y el pago será manejado posteriormente.
  /// ---------------------------------------------------------------------------
  Future<String> addPendingReservation({
    required String clientId,
    required String coachId,
    required String scheduleId,
    required double amount,
  }) async {
    // Validar identificadores obligatorios utilizando los validadores
    // existentes del DataSource.
    _validateClientId(clientId);
    _validateCoachId(coachId);
    _validateScheduleId(scheduleId);

    // El monto no puede ser negativo.
    _validateAmount(amount);

    // Firestore genera el ID único de la reservación.
    final document = _reservationsCollection.doc();

    // Crear la reservación con el estado inicial oficial `pending`.
    await document.set({
      'reservationId': document.id,
      'clientId': clientId.trim(),
      'coachId': coachId.trim(),
      'scheduleId': scheduleId.trim(),
      'status': 'pending',
      'amount': amount,

      // La fecha de creación es generada por el servidor de Firebase.
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Regresar el ID generado por Firestore.
    return document.id;
  }

  /// -------------------------------------------------------------------------
  /// Obtiene una reservación específica.
  /// -------------------------------------------------------------------------
  Future<DocumentSnapshot<Map<String, dynamic>>> getReservationDocument({
    required String reservationId,
  }) {
    _validateReservationId(reservationId);

    return _reservationsCollection
        .doc(reservationId.trim())
        .get();
  }

  /// -------------------------------------------------------------------------
  /// Obtiene las reservaciones de un cliente.
  ///
  /// La consulta utiliza únicamente el campo oficial `clientId`.
  /// No se agrega orderBy para evitar requerir índices adicionales
  /// que todavía no sean necesarios.
  /// -------------------------------------------------------------------------
  Future<QuerySnapshot<Map<String, dynamic>>> getClientReservationDocuments({
    required String clientId,
  }) {
    _validateClientId(clientId);

    return _reservationsCollection
        .where(
      'clientId',
      isEqualTo: clientId.trim(),
    )
        .get();
  }

  /// -------------------------------------------------------------------------
  /// Obtiene las reservaciones de un Coach.
  ///
  /// La consulta utiliza únicamente el campo oficial `coachId`.
  /// -------------------------------------------------------------------------
  Future<QuerySnapshot<Map<String, dynamic>>> getCoachReservationDocuments({
    required String coachId,
  }) {
    _validateCoachId(coachId);

    return _reservationsCollection
        .where(
      'coachId',
      isEqualTo: coachId.trim(),
    )
        .get();
  }

  /// Obtiene las reservaciones asociadas a un horario específico.
  Future<QuerySnapshot<Map<String, dynamic>>> getReservationsByScheduleId({
    required String scheduleId,
  }) {
    _validateScheduleId(scheduleId);

    return _reservationsCollection
        .where(
      'scheduleId',
      isEqualTo: scheduleId.trim(),
    )
        .get();
  }

  /// -------------------------------------------------------------------------
  /// Crea una nueva reservación.
  ///
  /// Este método conserva la funcionalidad general existente del DataSource.
  ///
  /// El estado será recibido desde la capa superior.
  /// Las reglas que determinan las transiciones de estado serán implementadas
  /// posteriormente como parte de las reglas de negocio.
  /// -------------------------------------------------------------------------
  Future<String> addReservation({
    required String clientId,
    required String coachId,
    required String scheduleId,
    String? paymentId,
    required String status,
    required double amount,
    required DateTime createdAt,
  }) async {
    _validateClientId(clientId);
    _validateCoachId(coachId);
    _validateScheduleId(scheduleId);
    _validateStatus(status);
    _validateAmount(amount);

    final document = _reservationsCollection.doc();

    final data = <String, dynamic>{
      // ID oficial de la reservación.
      'reservationId': document.id,

      // Cliente que realiza la reservación.
      'clientId': clientId.trim(),

      // Coach propietario del horario.
      'coachId': coachId.trim(),

      // Horario que se pretende reservar.
      'scheduleId': scheduleId.trim(),

      // El pago es opcional para una reservación pendiente.
      if (paymentId != null && paymentId.trim().isNotEmpty)
        'paymentId': paymentId.trim(),

      // Estado oficial de la reservación.
      'status': status.trim(),

      // Importe de la reservación.
      'amount': amount,

      // Fecha de creación.
      'createdAt': Timestamp.fromDate(createdAt),
    };

    await document.set(data);

    return document.id;
  }

  /// -------------------------------------------------------------------------
  /// Actualiza únicamente el estado de una reservación.
  ///
  /// Las transiciones permitidas se validarán posteriormente en la capa
  /// de dominio como parte de CK-016.4.
  /// -------------------------------------------------------------------------
  Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
  }) {
    _validateReservationId(reservationId);
    _validateStatus(status);

    return _reservationsCollection
        .doc(reservationId.trim())
        .update({
      'status': status.trim(),
    });
  }

  /// -------------------------------------------------------------------------
  /// Actualiza el paymentId de una reservación.
  ///
  /// Se mantiene separado de la actualización de estado para no modificar
  /// otros campos accidentalmente.
  /// -------------------------------------------------------------------------
  Future<void> updateReservationPayment({
    required String reservationId,
    required String paymentId,
  }) {
    _validateReservationId(reservationId);
    _validatePaymentId(paymentId);

    return _reservationsCollection
        .doc(reservationId.trim())
        .update({
      'paymentId': paymentId.trim(),
    });
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

  /// -------------------------------------------------------------------------
  /// Valida el paymentId.
  /// -------------------------------------------------------------------------
  void _validatePaymentId(String paymentId) {
    if (paymentId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del pago es obligatorio.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida el estado oficial de la reservación.
  ///
  /// Valores definidos:
  /// pending
  /// confirmed
  /// completed
  /// cancelled
  /// -------------------------------------------------------------------------
  void _validateStatus(String status) {
    const validStatuses = {
      'pending',
      'confirmed',
      'completed',
      'cancelled',
    };

    if (!validStatuses.contains(status.trim())) {
      throw ArgumentError(
        'Estado de reservación no válido: $status.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida que el importe no sea negativo.
  /// -------------------------------------------------------------------------
  void _validateAmount(double amount) {
    if (amount < 0) {
      throw ArgumentError(
        'El importe de la reservación no puede ser negativo.',
      );
    }
  }
}