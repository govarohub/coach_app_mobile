import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/coach_profile.dart';
import 'coach_profile_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: coach_search_provider.dart
///
/// CK-012.8
///
/// Estado de búsqueda y combinación de filtros de Coaches.
/// ---------------------------------------------------------------------------

/// Provider que obtiene todos los Coaches registrados en Firestore.
///
/// La consulta base continúa reutilizando el Repository existente.
final coachSearchProvider =
FutureProvider<List<CoachProfile>>((ref) async {
  // Reutilizamos el Repository existente del módulo Coach.
  final repository = ref.watch(
    coachProfileRepositoryProvider,
  );

  // Recuperamos todos los Coaches registrados.
  return repository.getCoaches();
});

/// Filtra una lista de Coaches por especialidad.
///
/// CK-012.3:
/// - Ignora mayúsculas y minúsculas.
/// - Ignora espacios al inicio y final.
/// - Permite coincidencias parciales.
///
/// Si la especialidad está vacía, devuelve todos los Coaches.
List<CoachProfile> filterCoachesBySpecialty({
  required List<CoachProfile> coaches,
  required String specialty,
}) {
  // Normalizamos el texto introducido por el usuario.
  final normalizedSpecialty = specialty.trim().toLowerCase();

  // Sin texto de búsqueda, no aplicamos el filtro.
  if (normalizedSpecialty.isEmpty) {
    return coaches;
  }

  // Conservamos los Coaches cuya especialidad coincida.
  return coaches.where((coach) {
    return coach.specialties.any(
          (coachSpecialty) {
        final normalizedCoachSpecialty =
        coachSpecialty.trim().toLowerCase();

        return normalizedCoachSpecialty.contains(
          normalizedSpecialty,
        );
      },
    );
  }).toList();
}

/// Filtra una lista de Coaches por disponibilidad.
///
/// CK-012.4:
/// Solamente se conservan los Coaches disponibles cuando
/// el filtro está activado.
List<CoachProfile> filterAvailableCoaches({
  required List<CoachProfile> coaches,
  required bool onlyAvailable,
}) {
  // Si el filtro está desactivado, conservamos todos.
  if (!onlyAvailable) {
    return coaches;
  }

  // Conservamos únicamente Coaches disponibles.
  return coaches.where((coach) => coach.available).toList();
}

/// Filtra una lista de Coaches por verificación.
///
/// CK-012.5:
/// Solamente se conservan los Coaches verificados cuando
/// el filtro está activado.
List<CoachProfile> filterVerifiedCoaches({
  required List<CoachProfile> coaches,
  required bool onlyVerified,
}) {
  // Si el filtro está desactivado, conservamos todos.
  if (!onlyVerified) {
    return coaches;
  }

  // Conservamos únicamente Coaches verificados.
  return coaches.where((coach) => coach.verified).toList();
}

/// Obtiene la posición actual del usuario.
///
/// CK-012.6:
/// Verifica que el servicio de ubicación esté disponible
/// y que la aplicación tenga los permisos necesarios.
Future<Position> getCurrentUserPosition() async {
  // Verificamos que el servicio de ubicación esté activo.
  final serviceEnabled =
  await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    throw StateError(
      'El servicio de ubicación está desactivado.',
    );
  }

  // Consultamos el permiso actual.
  var permission = await Geolocator.checkPermission();

  // Si todavía no se ha solicitado, pedimos permiso.
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  // El usuario rechazó el permiso.
  if (permission == LocationPermission.denied) {
    throw StateError(
      'El permiso de ubicación fue rechazado.',
    );
  }

  // El usuario rechazó permanentemente el permiso.
  if (permission == LocationPermission.deniedForever) {
    throw StateError(
      'El permiso de ubicación fue rechazado permanentemente.',
    );
  }

  // Obtenemos la posición actual del usuario.
  return Geolocator.getCurrentPosition();
}

/// Calcula la distancia en kilómetros entre el usuario
/// y un Coach.
///
/// CK-012.6:
/// Devuelve null cuando el Coach no tiene ubicación registrada.
double? calculateCoachDistanceKm({
  required Position userPosition,
  required CoachProfile coach,
}) {
  // Si el Coach no tiene ubicación, no podemos calcular
  // una distancia.
  final location = coach.location;

  if (location == null) {
    return null;
  }

  // Calculamos la distancia en metros.
  final distanceMeters = Geolocator.distanceBetween(
    userPosition.latitude,
    userPosition.longitude,
    location.latitude,
    location.longitude,
  );

  // Convertimos metros a kilómetros.
  return distanceMeters / 1000;
}

/// Ordena los Coaches de menor a mayor distancia.
///
/// CK-012.7:
/// - El Coach más cercano aparece primero.
/// - El Coach más lejano aparece después.
/// - Los Coaches sin ubicación quedan al final.
/// - No modifica la lista original.
List<CoachProfile> sortCoachesByDistance({
  required List<CoachProfile> coaches,
  required Map<String, double?> coachDistances,
}) {
  // Creamos una copia para no modificar la lista original.
  final sortedCoaches = List<CoachProfile>.from(coaches);

  // Ordenamos de acuerdo con la distancia calculada.
  sortedCoaches.sort(
        (a, b) {
      final distanceA = coachDistances[a.coachId];
      final distanceB = coachDistances[b.coachId];

      // Si ambos no tienen distancia, conservamos su posición relativa.
      if (distanceA == null && distanceB == null) {
        return 0;
      }

      // Los Coaches sin ubicación se colocan al final.
      if (distanceA == null) {
        return 1;
      }

      if (distanceB == null) {
        return -1;
      }

      // Orden ascendente: menor distancia primero.
      return distanceA.compareTo(distanceB);
    },
  );

  return sortedCoaches;
}

/// Resultado combinado de la búsqueda de Coaches.
///
/// CK-012.8:
/// Contiene los Coaches finales y las distancias calculadas.
class CoachSearchResult {
  const CoachSearchResult({
    required this.coaches,
    required this.distances,
  });

  /// Coaches que cumplen todos los filtros seleccionados.
  final List<CoachProfile> coaches;

  /// Distancia en kilómetros por Coach.
  ///
  /// El valor es null cuando el Coach no tiene ubicación.
  final Map<String, double?> distances;
}

/// Aplica todos los filtros disponibles y el ordenamiento.
///
/// CK-012.8:
/// Integra:
/// - CK-012.3: especialidad.
/// - CK-012.4: disponibilidad.
/// - CK-012.5: verificación.
/// - CK-012.6: distancia.
/// - CK-012.7: ordenamiento por distancia.
///
/// La ubicación del usuario es opcional.
///
/// Si no existe ubicación del usuario:
/// - Se aplican los filtros disponibles.
/// - No se calcula distancia.
/// - No se modifica el orden recibido.
///
/// Si existe ubicación del usuario:
/// - Se calcula la distancia.
/// - Los resultados se ordenan de menor a mayor distancia.
CoachSearchResult applyCoachSearchFilters({
  required List<CoachProfile> coaches,
  required String specialty,
  required bool onlyAvailable,
  required bool onlyVerified,
  Position? userPosition,
}) {
  // CK-012.3: filtro por especialidad.
  var filteredCoaches = filterCoachesBySpecialty(
    coaches: coaches,
    specialty: specialty,
  );

  // CK-012.4: filtro por disponibilidad.
  filteredCoaches = filterAvailableCoaches(
    coaches: filteredCoaches,
    onlyAvailable: onlyAvailable,
  );

  // CK-012.5: filtro por verificación.
  filteredCoaches = filterVerifiedCoaches(
    coaches: filteredCoaches,
    onlyVerified: onlyVerified,
  );

  // Mapa que relaciona cada Coach con su distancia.
  final distances = <String, double?>{};

  // CK-012.6:
  // Calculamos las distancias únicamente cuando conocemos
  // la ubicación actual del usuario.
  if (userPosition != null) {
    for (final coach in filteredCoaches) {
      distances[coach.coachId] =
          calculateCoachDistanceKm(
            userPosition: userPosition,
            coach: coach,
          );
    }

    // CK-012.7:
    // Ordenamos de menor a mayor distancia.
    filteredCoaches = sortCoachesByDistance(
      coaches: filteredCoaches,
      coachDistances: distances,
    );
  }

  // Devolvemos el resultado final de todos los filtros.
  return CoachSearchResult(
    coaches: filteredCoaches,
    distances: distances,
  );
}