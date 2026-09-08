import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/client_profile.dart';

class ClientProfileModel extends ClientProfile {
  const ClientProfileModel({
    required super.uid,
    required super.email,
    required super.name,
    super.phone,
    required super.role,
    super.photoUrl,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Construye el modelo a partir de un documento de Firestore.
  factory ClientProfileModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data();

    // El documento debe contener información para poder
    // construir correctamente el perfil.
    if (data == null) {
      throw StateError(
        'El documento users/${document.id} no contiene información.',
      );
    }

    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];

    return ClientProfileModel(
      // Utilizamos el uid almacenado en Firestore.
      // Si no existe, utilizamos el ID del documento.
      uid: data['uid'] as String? ?? document.id,

      // Datos básicos del perfil.
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String?,

      // Valores predeterminados para mantener compatibilidad
      // con documentos que todavía no tengan estos campos.
      role: data['role'] as String? ?? 'client',
      photoUrl: data['photoUrl'] as String?,
      status: data['status'] as String? ?? 'active',

      // Firestore almacena las fechas como Timestamp.
      // La entidad de dominio trabaja con DateTime.
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),

      updatedAt: updatedAt is Timestamp
          ? updatedAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Convierte el modelo a un mapa compatible con Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'role': role,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}