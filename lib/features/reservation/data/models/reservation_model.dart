import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/reservation.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: reservation_model.dart
///
/// CK-016.1
///
/// Modelo de persistencia de una reservación.
///
/// Se encarga exclusivamente de convertir entre Firestore y la entidad
/// de dominio Reservation.
/// ---------------------------------------------------------------------------

class ReservationModel extends Reservation {
  const ReservationModel({
    required super.reservationId,
    required super.clientId,
    required super.coachId,
    required super.scheduleId,
    super.paymentId,
    required super.status,
    required super.amount,
    required super.createdAt,
  });

  /// Construye el modelo a partir de un documento de Firestore.
  factory ReservationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data();

    // Un documento existente sin datos no puede convertirse
    // correctamente en una reservación.
    if (data == null) {
      throw StateError(
        'El documento reservations/${document.id} '
            'no contiene información.',
      );
    }

    final amountData = data['amount'];
    final createdAtData = data['createdAt'];

    // createdAt está definido como Timestamp en Firestore.
    if (createdAtData is! Timestamp) {
      throw StateError(
        'La reservación ${document.id} no contiene '
            'un createdAt válido.',
      );
    }

    return ReservationModel(
      // El campo oficial reservationId tiene prioridad.
      // El ID del documento funciona como respaldo.
      reservationId:
      data['reservationId'] as String? ?? document.id,

      // Identificador del cliente.
      clientId: data['clientId'] as String? ?? '',

      // Identificador del Coach.
      coachId: data['coachId'] as String? ?? '',

      // Identificador del horario.
      scheduleId: data['scheduleId'] as String? ?? '',

      // El pago es opcional mientras la reserva esté pendiente.
      paymentId: data['paymentId'] as String?,

      // Estado oficial de la reservación.
      status: data['status'] as String? ?? 'pending',

      // Firestore puede devolver int o double.
      amount: amountData is num
          ? amountData.toDouble()
          : 0.0,

      // Conversión de Timestamp a DateTime.
      createdAt: createdAtData.toDate(),
    );
  }

  /// Convierte el modelo a los campos oficiales de Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'reservationId': reservationId,
      'clientId': clientId,
      'coachId': coachId,
      'scheduleId': scheduleId,

      // paymentId solamente se persiste cuando existe.
      if (paymentId != null && paymentId!.trim().isNotEmpty)
        'paymentId': paymentId,

      'status': status,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}