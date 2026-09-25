import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de persistencia de un favorito.
///
/// CK-014.1 — Modelo de datos.
///
/// Firestore:
/// users/{uid}/favorites/{coachId}
///
/// Este modelo representa únicamente la relación de persistencia.
/// Los datos completos del Coach siguen perteneciendo al módulo `coach`.
class FavoriteCoachModel {
  const FavoriteCoachModel({
    required this.coachId,
    this.createdAt,
  });

  /// Identificador del Coach favorito.
  final String coachId;

  /// Fecha de creación de la relación, cuando ya fue resuelta por Firestore.
  final DateTime? createdAt;

  /// Construye el modelo desde un documento de Firestore.
  factory FavoriteCoachModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data();

    final storedCoachId = data?['coachId'];

    // El campo coachId es la fuente principal.
    // El ID del documento funciona como respaldo para documentos existentes.
    final resolvedCoachId =
    storedCoachId is String && storedCoachId.trim().isNotEmpty
        ? storedCoachId.trim()
        : document.id;

    if (resolvedCoachId.trim().isEmpty) {
      throw StateError(
        'El favorito ${document.id} no contiene un coachId válido.',
      );
    }

    final createdAtData = data?['createdAt'];

    DateTime? resolvedCreatedAt;

    // Firestore normalmente entrega Timestamp.
    if (createdAtData is Timestamp) {
      resolvedCreatedAt = createdAtData.toDate();
    } else if (createdAtData is DateTime) {
      // Se admite DateTime para facilitar pruebas/local mocks.
      resolvedCreatedAt = createdAtData;
    }

    return FavoriteCoachModel(
      coachId: resolvedCoachId,
      createdAt: resolvedCreatedAt,
    );
  }

  /// Convierte el modelo a los datos que serán almacenados en Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'coachId': coachId,

      // La fecha la asigna el servidor para evitar depender
      // del reloj del dispositivo del cliente.
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}