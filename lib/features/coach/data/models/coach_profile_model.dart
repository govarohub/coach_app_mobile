import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/coach_profile.dart';

/// Modelo de datos del Perfil Profesional del Coach.
class CoachProfileModel extends CoachProfile {
  const CoachProfileModel({
    required super.coachId,
    required super.specialties,
    required super.experienceYears,
    required super.hourlyRate,
    required super.rating,
    required super.verified,
    super.bio,
    super.location,
    required super.available,
  });

  /// Construye el modelo a partir de un documento Firestore.
  factory CoachProfileModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data();

    // El documento debe contener información.
    if (data == null) {
      throw StateError(
        'El documento coaches/${document.id} no contiene información.',
      );
    }

    // Recuperamos las especialidades.
    final specialtiesData = data['specialties'];

    final specialties = specialtiesData is List
        ? specialtiesData
        .whereType<String>()
        .map((specialty) => specialty.trim())
        .where((specialty) => specialty.isNotEmpty)
        .toList()
        : <String>[];

    // Recuperamos los años de experiencia.
    final experienceData = data['experienceYears'];

    // Recuperamos los demás campos numéricos.
    final hourlyRateData = data['hourlyRate'];
    final ratingData = data['rating'];

    // Recuperamos la ubicación de Firestore.
    final locationData = data['location'];

    CoachLocation? location;

    if (locationData is GeoPoint) {
      location = CoachLocation(
        latitude: locationData.latitude,
        longitude: locationData.longitude,
      );
    }

    return CoachProfileModel(
      // ID del Coach.
      coachId: data['coachId'] as String? ?? document.id,

      // Especialidades profesionales.
      specialties: specialties,

      // Años de experiencia.
      experienceYears: experienceData is num
          ? experienceData.toInt()
          : 0,

      // Tarifa por hora.
      hourlyRate: hourlyRateData is num
          ? hourlyRateData.toDouble()
          : 0.0,

      // Calificación.
      rating: ratingData is num
          ? ratingData.toDouble()
          : 0.0,

      // Verificación.
      verified: data['verified'] as bool? ?? false,

      // Biografía opcional.
      bio: data['bio'] as String?,

      // Ubicación.
      location: location,

      // Disponibilidad.
      available: data['available'] as bool? ?? false,
    );
  }

  /// Convierte el modelo a un mapa de Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      // Especialidades profesionales.
      'specialties': specialties,

      // Años de experiencia.
      'experienceYears': experienceYears,

      // Biografía profesional.
      'bio': bio,

      // Los demás campos forman parte del modelo,
      // pero no son modificados específicamente por CK-010.5.
      'coachId': coachId,
      'hourlyRate': hourlyRate,
      'rating': rating,
      'verified': verified,
      'location': location == null
          ? null
          : GeoPoint(
        location!.latitude,
        location!.longitude,
      ),
      'available': available,
    };
  }
}