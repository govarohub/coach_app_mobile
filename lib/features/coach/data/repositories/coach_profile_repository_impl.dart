import '../../domain/entities/coach_profile.dart';
import '../../domain/entities/coach_public_identity.dart';
import '../../domain/repositories/coach_profile_repository.dart';
import '../datasources/firebase_coach_datasource.dart';
import '../models/coach_profile_model.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: coach_profile_repository_impl.dart
///
/// Implementación concreta del Repository del perfil profesional del Coach.
///
/// CK-012.2
/// Consulta de Coaches desde Firestore.
///
/// CK-013.3
/// Consulta de la identidad pública del Coach.
/// ---------------------------------------------------------------------------

class CoachProfileRepositoryImpl implements CoachProfileRepository {
  CoachProfileRepositoryImpl({
    required this._dataSource,
  });

  /// DataSource utilizado para acceder a Firestore.
  final FirebaseCoachDataSource _dataSource;

  /// -------------------------------------------------------------------------
  /// Obtiene el perfil profesional de un Coach.
  /// -------------------------------------------------------------------------
  @override
  Future<CoachProfile> getProfile(String coachId) async {
    // Consulta coaches/{coachId}.
    final document = await _dataSource.getCoachDocument(coachId);

    // Verifica que el documento exista.
    if (!document.exists) {
      throw StateError(
        'No existe el perfil profesional del Coach.',
      );
    }

    // Convierte el documento Firestore en la entidad de dominio.
    return CoachProfileModel.fromFirestore(document);
  }

  /// -------------------------------------------------------------------------
  /// Obtiene todos los perfiles profesionales registrados.
  ///
  /// CK-012.2:
  /// Consulta la colección `coaches` y transforma cada documento
  /// en una entidad CoachProfile.
  ///
  /// En este punto no se aplican filtros.
  /// -------------------------------------------------------------------------
  @override
  Future<List<CoachProfile>> getCoaches() async {
    // Obtiene todos los documentos de la colección coaches.
    final snapshot = await _dataSource.getCoachDocuments();

    // Convierte cada documento Firestore en CoachProfile.
    return snapshot.docs
        .map(CoachProfileModel.fromFirestore)
        .toList();
  }

  /// -------------------------------------------------------------------------
  /// CK-013.3
  ///
  /// Obtiene la identidad pública del Coach desde users/{coachId}.
  ///
  /// El nombre pertenece al documento de usuario y se mantiene separado
  /// del perfil profesional para evitar duplicar información en `coaches`.
  /// -------------------------------------------------------------------------
  @override
  Future<CoachPublicIdentity> getPublicIdentity(String coachId) async {
    // Consulta el documento del usuario asociado al Coach.
    final document = await _dataSource.getCoachUserDocument(coachId);

    // Verifica que el usuario exista.
    if (!document.exists) {
      throw StateError(
        'No existe la identidad del Coach.',
      );
    }

    // Obtiene los datos del documento.
    final data = document.data();

    // Verifica que el documento contenga información.
    if (data == null) {
      throw StateError(
        'El documento del usuario no contiene información.',
      );
    }

    // El nombre público se obtiene del campo existente `name`.
    final name = data['name'] as String? ?? '';

    // La identidad pública requiere un nombre válido.
    if (name.trim().isEmpty) {
      throw StateError(
        'El Coach no tiene un nombre registrado.',
      );
    }

    /// Construye la identidad pública incluyendo la fotografía,
    /// cuando existe.
    return CoachPublicIdentity(
      name: name.trim(),
      photoUrl: data['photoUrl'] as String?,
    );
  }

  /// -------------------------------------------------------------------------
  /// Actualiza la información profesional del Coach.
  /// -------------------------------------------------------------------------
  @override
  Future<CoachProfile> updateProfile({
    required String coachId,
    required List<String> specialties,
    required int experienceYears,
    required double hourlyRate,
    required String? bio,
    required CoachLocation? location,
    required bool available,
  }) async {
    // Normaliza las especialidades eliminando espacios
    // y valores vacíos.
    final normalizedSpecialties = <String>[];
    final specialtyKeys = <String>{};

    for (final specialty in specialties) {
      final normalized = specialty.trim();

      if (normalized.isEmpty) {
        continue;
      }

      // Evita duplicados ignorando mayúsculas y minúsculas.
      final key = normalized.toLowerCase();

      if (specialtyKeys.add(key)) {
        normalizedSpecialties.add(normalized);
      }
    }

    // Normaliza la biografía.
    final normalizedBio = bio?.trim();

    // Valida los datos antes de acceder a Firestore.
    _validateCoachId(coachId);
    _validateSpecialties(normalizedSpecialties);
    _validateExperienceYears(experienceYears);
    _validateHourlyRate(hourlyRate);
    _validateLocation(location);

    // Actualiza la información profesional.
    await _dataSource.updateCoachProfile(
      coachId: coachId,
      specialties: normalizedSpecialties,
      experienceYears: experienceYears,
      hourlyRate: hourlyRate,
      bio: normalizedBio?.isEmpty == true
          ? null
          : normalizedBio,
      latitude: location?.latitude,
      longitude: location?.longitude,
      available: available,
    );

    // Recupera el documento después de actualizarlo.
    final document = await _dataSource.getCoachDocument(coachId);

    // Verifica que el documento exista.
    if (!document.exists) {
      throw StateError(
        'No fue posible recuperar el perfil profesional actualizado.',
      );
    }

    // Devuelve el perfil actualizado.
    return CoachProfileModel.fromFirestore(document);
  }

  /// -------------------------------------------------------------------------
  /// Actualiza únicamente la disponibilidad profesional del Coach.
  ///
  /// Después de guardar el estado, vuelve a consultar Firestore
  /// para devolver el perfil realmente persistido.
  /// -------------------------------------------------------------------------
  Future<CoachProfile> updateAvailability({
    required String coachId,
    required bool available,
  }) async {
    // Valida el identificador.
    _validateCoachId(coachId);

    // Guarda el estado de disponibilidad.
    await _dataSource.updateCoachAvailability(
      coachId: coachId,
      available: available,
    );

    // Recupera el documento actualizado.
    final document = await _dataSource.getCoachDocument(coachId);

    // Verifica que el perfil continúe existiendo.
    if (!document.exists) {
      throw StateError(
        'No fue posible recuperar el perfil profesional actualizado.',
      );
    }

    // Devuelve el perfil actualizado.
    return CoachProfileModel.fromFirestore(document);
  }

  /// -------------------------------------------------------------------------
  /// Actualiza la ubicación profesional del Coach.
  ///
  /// Después de guardar la ubicación, vuelve a consultar Firestore
  /// para devolver el perfil realmente persistido.
  /// -------------------------------------------------------------------------
  Future<CoachProfile> updateLocation({
    required String coachId,
    required CoachLocation? location,
  }) async {
    // Valida el identificador y las coordenadas.
    _validateCoachId(coachId);
    _validateLocation(location);

    // Guarda la ubicación en Firestore.
    await _dataSource.updateCoachLocation(
      coachId: coachId,
      latitude: location?.latitude,
      longitude: location?.longitude,
    );

    // Recupera el documento actualizado.
    final document = await _dataSource.getCoachDocument(coachId);

    // Verifica que el perfil continúe existiendo.
    if (!document.exists) {
      throw StateError(
        'No fue posible recuperar el perfil profesional actualizado.',
      );
    }

    // Devuelve el perfil actualizado.
    return CoachProfileModel.fromFirestore(document);
  }

  /// -------------------------------------------------------------------------
  /// Actualiza únicamente la tarifa por hora del Coach.
  ///
  /// Después de guardar el valor, vuelve a consultar Firestore
  /// para devolver el estado realmente persistido.
  /// -------------------------------------------------------------------------
  Future<CoachProfile> updateHourlyRate({
    required String coachId,
    required double hourlyRate,
  }) async {
    // Valida los datos.
    _validateCoachId(coachId);
    _validateHourlyRate(hourlyRate);

    // Guarda la tarifa en Firestore.
    await _dataSource.updateCoachHourlyRate(
      coachId: coachId,
      hourlyRate: hourlyRate,
    );

    // Recupera el documento actualizado.
    final document = await _dataSource.getCoachDocument(coachId);

    // Verifica que el perfil continúe existiendo.
    if (!document.exists) {
      throw StateError(
        'No fue posible recuperar el perfil profesional actualizado.',
      );
    }

    // Devuelve el perfil actualizado.
    return CoachProfileModel.fromFirestore(document);
  }

  /// -------------------------------------------------------------------------
  /// Actualiza la referencia de la fotografía del Coach.
  /// -------------------------------------------------------------------------
  Future<void> updatePhoto({
    required String uid,
    required String? photoUrl,
  }) {
    // Valida que exista un usuario asociado.
    _validateCoachId(uid);

    // Actualiza únicamente la referencia de la fotografía.
    return _dataSource.updateCoachPhoto(
      uid: uid,
      photoUrl: photoUrl,
    );
  }

  /// -------------------------------------------------------------------------
  /// Valida que el identificador del Coach exista.
  /// -------------------------------------------------------------------------
  void _validateCoachId(String coachId) {
    if (coachId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del Coach es obligatorio.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida las especialidades del perfil profesional.
  /// -------------------------------------------------------------------------
  void _validateSpecialties(List<String> specialties) {
    if (specialties.isEmpty) {
      throw ArgumentError(
        'El Coach debe tener al menos una especialidad.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida los años de experiencia profesional.
  /// -------------------------------------------------------------------------
  void _validateExperienceYears(int experienceYears) {
    if (experienceYears < 0) {
      throw ArgumentError(
        'Los años de experiencia no pueden ser negativos.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida la tarifa por hora.
  /// -------------------------------------------------------------------------
  void _validateHourlyRate(double hourlyRate) {
    if (!hourlyRate.isFinite || hourlyRate <= 0) {
      throw ArgumentError(
        'La tarifa por hora debe ser mayor que cero.',
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida que las coordenadas geográficas estén dentro
  /// de los rangos válidos.
  /// -------------------------------------------------------------------------
  void _validateLocation(CoachLocation? location) {
    // La ubicación es opcional.
    if (location == null) {
      return;
    }

    // Latitud válida: -90 a 90 grados.
    if (!location.latitude.isFinite ||
        location.latitude < -90 ||
        location.latitude > 90) {
      throw ArgumentError(
        'La latitud debe estar entre -90 y 90.',
      );
    }

    // Longitud válida: -180 a 180 grados.
    if (!location.longitude.isFinite ||
        location.longitude < -180 ||
        location.longitude > 180) {
      throw ArgumentError(
        'La longitud debe estar entre -180 y 180.',
      );
    }
  }
}