import 'package:cloud_firestore/cloud_firestore.dart';

/// DataSource de Firebase para el perfil profesional del Coach.
class FirebaseCoachDataSource {
  FirebaseCoachDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Instancia de Firestore utilizada para acceder a la colección coaches.
  final FirebaseFirestore _firestore;

  /// Actualiza la fotografía asociada al usuario del Coach.
  ///
  /// La fotografía pertenece al documento `users`, no al documento
  /// profesional `coaches`, evitando duplicar información.
  Future<void> updateCoachPhoto({
    required String uid,
    required String? photoUrl,
  }) {
    return _firestore.collection('users').doc(uid).update({
      // URL de la fotografía almacenada en Firebase Storage.
      'photoUrl': photoUrl,

      // Fecha de última modificación del usuario.
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza únicamente la disponibilidad profesional del Coach.
  ///
  /// CK-010.8:
  /// Firestore almacena la disponibilidad mediante el campo
  /// booleano `available`.
  ///
  /// true  = available
  /// false = unavailable
  ///
  /// También se actualiza `updatedAt` para conservar la trazabilidad
  /// de la modificación.
  Future<void> updateCoachAvailability({
    required String coachId,
    required bool available,
  }) {
    return _firestore.collection('coaches').doc(coachId).update({
      // Estado actual de disponibilidad del Coach.
      'available': available,

      // Fecha de última modificación.
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza únicamente la ubicación profesional del Coach.
  ///
  /// CK-010.7:
  /// Firestore almacena la ubicación como un GeoPoint.
  ///
  /// Si latitude y longitude son null, se elimina la ubicación
  /// utilizando FieldValue.delete().
  Future<void> updateCoachLocation({
    required String coachId,
    required double? latitude,
    required double? longitude,
  }) {
    // Si ambas coordenadas existen, se crea el GeoPoint.
    if (latitude != null && longitude != null) {
      return _firestore.collection('coaches').doc(coachId).update({
        'location': GeoPoint(latitude, longitude),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Si no existe una ubicación completa, se elimina el campo.
    return _firestore.collection('coaches').doc(coachId).update({
      'location': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Obtiene el documento del Coach:
  ///
  /// coaches/{coachId}
  Future<DocumentSnapshot<Map<String, dynamic>>> getCoachDocument(
      String coachId,
      ) {
    return _firestore.collection('coaches').doc(coachId).get();
  }

  /// Obtiene todos los documentos de la colección de Coaches.
  ///
  /// CK-012.2:
  /// Esta consulta solamente recupera los Coaches existentes.
  ///
  /// Los filtros de disponibilidad, verificación, especialidad
  /// y ubicación se implementarán en los siguientes sub-CK.
  Future<QuerySnapshot<Map<String, dynamic>>> getCoachDocuments() {
    return _firestore.collection('coaches').get();
  }

  /// ---------------------------------------------------------------------------
  /// CK-013.3
  ///
  /// Obtiene el documento de usuario asociado al Coach.
  ///
  /// El nombre pertenece a `users/{coachId}` y no al documento profesional
  /// `coaches/{coachId}`. De esta forma evitamos duplicar información.
  /// ---------------------------------------------------------------------------
  Future<DocumentSnapshot<Map<String, dynamic>>> getCoachUserDocument(
      String coachId,
      ) {
    return _firestore.collection('users').doc(coachId).get();
  }


  /// Actualiza únicamente la tarifa por hora del Coach.
  ///
  /// CK-010.6:
  /// La tarifa se almacena en Firestore como Number.
  ///
  /// No modifica especialidades, experiencia, biografía,
  /// ubicación, disponibilidad, rating ni verified.
  Future<void> updateCoachHourlyRate({
    required String coachId,
    required double hourlyRate,
  }) {
    return _firestore.collection('coaches').doc(coachId).update({
      // Tarifa por hora del Coach.
      'hourlyRate': hourlyRate,

      // Fecha de modificación del documento.
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza la información profesional editable del Coach.
  ///
  /// No se actualizan rating ni verified porque esos valores
  /// no son administrados directamente por el Coach.
  Future<void> updateCoachProfile({
    required String coachId,
    required List<String> specialties,
    required int experienceYears,
    required double hourlyRate,
    required String? bio,
    required double? latitude,
    required double? longitude,
    required bool available,
  }) {
    // Construimos la ubicación solamente cuando existen
    // latitud y longitud.
    final GeoPoint? location;

    if (latitude != null && longitude != null) {
      location = GeoPoint(latitude, longitude);
    } else {
      location = null;
    }

    return _firestore.collection('coaches').doc(coachId).update({
      // Información profesional editable.
      'specialties': specialties,
      'experienceYears': experienceYears,
      'hourlyRate': hourlyRate,
      'bio': bio,

      // Ubicación profesional.
      'location': location,

      // Disponibilidad actual del Coach.
      'available': available,

      // Fecha de modificación del documento.
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}