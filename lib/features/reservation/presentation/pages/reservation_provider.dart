import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/providers/auth_state_provider.dart';
import '../../../coach/domain/entities/coach_schedule.dart';
import '../../../coach/presentation/pages/coach_schedule_provider.dart';
import '../../data/datasources/firebase_reservation_datasource.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../../domain/services/reservation_business_rules.dart';

/// ---------------------------------------------------------------------------
/// DataSource de Reservaciones.
/// ---------------------------------------------------------------------------
final firebaseReservationDataSourceProvider =
Provider<FirebaseReservationDataSource>((ref) {
  return FirebaseReservationDataSource();
});

/// ---------------------------------------------------------------------------
/// Repository de Reservaciones.
///
/// La capa de presentación no accede directamente a Firebase.
/// ---------------------------------------------------------------------------
final reservationRepositoryProvider =
Provider<ReservationRepository>((ref) {
  final dataSource = ref.watch(
    firebaseReservationDataSourceProvider,
  );

  return ReservationRepositoryImpl(
    dataSource: dataSource,
  );
});

/// ---------------------------------------------------------------------------
/// Obtiene una reservación mediante su identificador.
///
/// CK-017.10:
/// El estado de la reservación se valida en la capa de dominio antes de
/// entregarla a la presentación.
/// ---------------------------------------------------------------------------
final reservationProvider =
FutureProvider.family<Reservation, String>(
      (ref, reservationId) async {
    // Obtiene el Repository existente.
    final repository = ref.watch(
      reservationRepositoryProvider,
    );

    // Consulta la reservación.
    final reservation = await repository.getReservation(
      reservationId,
    );

    // Valida el estado oficial en la entidad de dominio.
    reservation.validateOfficialStatus();

    return reservation;
  },
);

/// ---------------------------------------------------------------------------
/// Obtiene las reservaciones del cliente autenticado.
///
/// CK-017.10:
/// Todas las reservaciones obtenidas deben utilizar estados oficiales.
/// ---------------------------------------------------------------------------
final clientReservationsProvider =
FutureProvider<List<Reservation>>((ref) async {
  // Obtiene el usuario autenticado.
  final authState = await ref.watch(
    authStateProvider.future,
  );

  // No se permite consultar reservaciones sin sesión.
  if (authState == null) {
    throw StateError(
      'No existe una sesión de usuario activa.',
    );
  }

  // Obtiene el Repository existente.
  final repository = ref.watch(
    reservationRepositoryProvider,
  );

  // Consulta las reservaciones del cliente.
  final reservations = await repository.getClientReservations(
    authState.id,
  );

  // -------------------------------------------------------------------------
  // CK-017.10
  //
  // Valida cada estado mediante la entidad de dominio.
  // -------------------------------------------------------------------------
  for (final reservation in reservations) {
    reservation.validateOfficialStatus();
  }

  return reservations;
});

/// ---------------------------------------------------------------------------
/// Obtiene las reservaciones de un Coach.
///
/// CK-017.10:
/// Todas las reservaciones obtenidas deben utilizar estados oficiales.
/// ---------------------------------------------------------------------------
final coachReservationsProvider =
FutureProvider.family<List<Reservation>, String>(
      (ref, coachId) async {
    // Obtiene el Repository existente.
    final repository = ref.watch(
      reservationRepositoryProvider,
    );

    // Consulta las reservaciones del Coach.
    final reservations = await repository.getCoachReservations(
      coachId,
    );

    // -------------------------------------------------------------------------
    // CK-017.10
    //
    // Valida cada estado mediante la entidad de dominio.
    // -------------------------------------------------------------------------
    for (final reservation in reservations) {
      reservation.validateOfficialStatus();
    }

    return reservations;
  },
);

/// ---------------------------------------------------------------------------
/// CK-017.7
///
/// Obtiene las reservaciones del cliente junto con el horario asociado.
///
/// El Repository de CoachSchedule existente proporciona la información del
/// horario necesaria para separar próximas sesiones e historial.
/// ---------------------------------------------------------------------------
final clientReservationsWithSchedulesProvider =
FutureProvider<List<({
Reservation reservation,
CoachSchedule schedule,
})>>((ref) async {
  // Obtiene las reservaciones previamente validadas.
  final reservations = await ref.watch(
    clientReservationsProvider.future,
  );

  // Obtiene el Repository existente de horarios.
  final scheduleRepository = ref.watch(
    coachScheduleRepositoryProvider,
  );

  // Asocia cada reservación con su horario.
  return Future.wait(
    reservations.map((reservation) async {
      final schedule = await scheduleRepository.getSchedule(
        reservation.scheduleId,
      );

      return (
      reservation: reservation,
      schedule: schedule,
      );
    }),
  );
});

/// ---------------------------------------------------------------------------
/// CK-017.7
///
/// Obtiene las reservaciones del Coach junto con sus horarios.
///
/// Permite separar próximas sesiones e historial utilizando la fecha real
/// del horario.
/// ---------------------------------------------------------------------------
final coachReservationsWithSchedulesProvider =
FutureProvider.family<List<({
Reservation reservation,
CoachSchedule schedule,
})>, String>((ref, coachId) async {
  // Obtiene las reservaciones previamente validadas.
  final reservations = await ref.watch(
    coachReservationsProvider(coachId).future,
  );

  // Obtiene el Repository existente de horarios.
  final scheduleRepository = ref.watch(
    coachScheduleRepositoryProvider,
  );

  // Asocia cada reservación con su horario.
  return Future.wait(
    reservations.map((reservation) async {
      final schedule = await scheduleRepository.getSchedule(
        reservation.scheduleId,
      );

      return (
      reservation: reservation,
      schedule: schedule,
      );
    }),
  );
});

/// Obtiene todos los horarios del Coach y asocia la reservación más reciente,
/// si existe, para mostrar disponibilidad y sesiones reservadas en su agenda.
final coachAgendaItemsProvider = FutureProvider.family<List<({
  Reservation? reservation,
  CoachSchedule schedule,
})>, String>((ref, coachId) async {
  final schedules = await ref.watch(
    coachSchedulesProvider(coachId).future,
  );
  final reservations = await ref.watch(
    coachReservationsProvider(coachId).future,
  );

  final reservationsByScheduleId = <String, Reservation>{};
  final newestFirstReservations = [...reservations]
    ..sort((first, second) => second.createdAt.compareTo(first.createdAt));

  for (final reservation in newestFirstReservations) {
    reservationsByScheduleId.putIfAbsent(
      reservation.scheduleId,
      () => reservation,
    );
  }

  return schedules
      .where((schedule) => schedule.status != 'blocked')
      .map((schedule) => (
            reservation: reservationsByScheduleId[schedule.scheduleId],
            schedule: schedule,
          ))
      .toList();
});

/// ---------------------------------------------------------------------------
/// Controller de Reservaciones.
///
/// Responsabilidades:
/// - Obtener el usuario autenticado.
/// - Solicitar operaciones al Repository.
/// - Mantener el estado loading/error/data.
///
/// No contiene código de Firestore.
/// ---------------------------------------------------------------------------
class ReservationController extends AsyncNotifier<void> {
  /// -------------------------------------------------------------------------
  /// CK-016.9
  ///
  /// Crea una reservación pendiente y marca el horario como reservado.
  ///
  /// Flujo:
  /// 1. Obtiene el usuario autenticado.
  /// 2. Crea la reservación con estado `pending`.
  /// 3. Cambia el horario de `available` a `reserved`.
  /// 4. Actualiza los providers correspondientes.
  /// -------------------------------------------------------------------------
  Future<String> createPendingReservationAndReserveSchedule({
    required String coachId,
    required String scheduleId,
    required double amount,
  }) async {
    state = const AsyncLoading();

    try {
      // -----------------------------------------------------------------------
      // 1. Obtener usuario autenticado.
      // -----------------------------------------------------------------------
      final authState = await ref.read(
        authStateProvider.future,
      );

      if (authState == null) {
        throw StateError(
          'No existe una sesión de usuario activa.',
        );
      }

      final repository = ref.read(reservationRepositoryProvider);
      final scheduleRepository = ref.read(coachScheduleRepositoryProvider);

      final schedule = await scheduleRepository.getSchedule(scheduleId);
      ReservationBusinessRules.validateScheduleCanBeReserved(schedule.status);

      final hasExistingReservation = await repository.hasActiveReservationForSchedule(
        scheduleId,
      );
      ReservationBusinessRules.validateNoDoubleBooking(
        hasExistingReservation: hasExistingReservation,
      );

      // -----------------------------------------------------------------------
      // 2. Crear la reservación con estado inicial `pending`.
      // -----------------------------------------------------------------------
      final reservationId = await repository.createPendingReservation(
        clientId: authState.id,
        coachId: coachId,
        scheduleId: scheduleId,
        amount: amount,
      );

      // -----------------------------------------------------------------------
      // 3. Marcar el horario como reservado.
      //
      // Este cambio pertenece al flujo de reservación y no utiliza la
      // validación de bloqueo/desbloqueo manual de CK-015.11.
      // -----------------------------------------------------------------------
      await scheduleRepository.updateScheduleStatus(
        scheduleId: scheduleId,
        status: 'reserved',
      );

      // Actualizar estado del Controller.
      state = const AsyncData(null);

      // Actualizar consultas relacionadas.
      ref.invalidate(
        coachSchedulesProvider(coachId),
      );
      ref.invalidate(
        coachAvailableSchedulesProvider(coachId),
      );
      ref.invalidate(
        clientReservationsProvider,
      );
      ref.invalidate(
        clientReservationsWithSchedulesProvider,
      );
      ref.invalidate(
        coachReservationsProvider(coachId),
      );

      return reservationId;
    } catch (error, stackTrace) {
      // Conservar el error en el Controller.
      state = AsyncError(
        error,
        stackTrace,
      );

      // Permitir que la pantalla maneje el error.
      rethrow;
    }
  }

  /// -------------------------------------------------------------------------
  /// Inicializa el AsyncNotifier.
  /// -------------------------------------------------------------------------
  @override
  Future<void> build() async {}

  /// -------------------------------------------------------------------------
  /// CK-016.8
  ///
  /// Crea una reservación inicial con estado `pending`.
  /// -------------------------------------------------------------------------
  Future<String> createPendingReservation({
    required String coachId,
    required String scheduleId,
    required double amount,
  }) async {
    state = const AsyncLoading();

    try {
      // Obtener usuario autenticado.
      final authState = await ref.read(
        authStateProvider.future,
      );

      // No se permite crear una reservación sin sesión.
      if (authState == null) {
        throw StateError(
          'No existe una sesión de usuario activa.',
        );
      }

      // Obtener Repository existente.
      final repository = ref.read(
        reservationRepositoryProvider,
      );

      // Crear la reservación con estado inicial `pending`.
      final reservationId =
      await repository.createPendingReservation(
        clientId: authState.id,
        coachId: coachId,
        scheduleId: scheduleId,
        amount: amount,
      );

      // Actualizar estado del Controller.
      state = const AsyncData(null);

      // Actualizar consulta de reservaciones del cliente.
      ref.invalidate(
        clientReservationsProvider,
      );

      return reservationId;
    } catch (error, stackTrace) {
      // Conservar el error en el Controller.
      state = AsyncError(
        error,
        stackTrace,
      );

      rethrow;
    }
  }

  /// -------------------------------------------------------------------------
  /// CK-017.10
  ///
  /// Actualiza el estado de una reservación.
  ///
  /// La validación del estado se realiza en la entidad de dominio antes de
  /// enviarlo al Repository.
  ///
  /// IMPORTANTE:
  /// Aquí únicamente validamos que el estado pertenezca al catálogo oficial.
  /// No inventamos nuevas reglas de transición.
  /// -------------------------------------------------------------------------
  Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
  }) async {
    state = const AsyncLoading();

    try {
      // -----------------------------------------------------------------------
      // Validar el estado mediante la capa de dominio.
      //
      // Estados permitidos:
      // pending
      // confirmed
      // completed
      // cancelled
      // -----------------------------------------------------------------------
      Reservation.validateStatus(status);

      // Obtener Repository existente.
      final repository = ref.read(
        reservationRepositoryProvider,
      );

      // Persistir el nuevo estado.
      await repository.updateReservationStatus(
        reservationId: reservationId,
        status: status,
      );

      // Actualizar estado del Controller.
      state = const AsyncData(null);

      // Actualizar reservación individual.
      ref.invalidate(
        reservationProvider(reservationId),
      );

      // Actualizar reservaciones del cliente.
      ref.invalidate(
        clientReservationsProvider,
      );
    } catch (error, stackTrace) {
      // Conservar el error en el Controller.
      state = AsyncError(
        error,
        stackTrace,
      );

      rethrow;
    }
  }

  /// Completes a reservation from the assigned coach agenda after its end time.
  Future<void> completeReservationAsCoach({
    required String reservationId,
  }) async {
    state = const AsyncLoading();

    try {
      final authState = await ref.read(authStateProvider.future);
      if (authState == null || authState.role.trim() != 'coach') {
        throw StateError('Solo el Coach asignado puede completar la sesión.');
      }

      final reservationRepository = ref.read(reservationRepositoryProvider);
      final reservation = await reservationRepository.getReservation(
        reservationId,
      );
      reservation.validateOfficialStatus();

      if (reservation.coachId != authState.id) {
        throw StateError('La sesión no pertenece a este Coach.');
      }

      ReservationBusinessRules.validateReservationCanBeCompleted(
        status: reservation.status,
      );

      await reservationRepository.updateReservationStatus(
        reservationId: reservation.reservationId,
        status: 'completed',
      );

      state = const AsyncData(null);
      ref.invalidate(reservationProvider(reservation.reservationId));
      ref.invalidate(clientReservationsProvider);
      ref.invalidate(clientReservationsWithSchedulesProvider);
      ref.invalidate(coachReservationsProvider(reservation.coachId));
      ref.invalidate(coachReservationsWithSchedulesProvider(reservation.coachId));
      ref.invalidate(coachAgendaItemsProvider(reservation.coachId));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// -------------------------------------------------------------------------
  /// Asocia un pago a una reservación.
  /// -------------------------------------------------------------------------
  Future<void> updateReservationPayment({
    required String reservationId,
    required String paymentId,
  }) async {
    state = const AsyncLoading();

    try {
      // Obtener Repository existente.
      final repository = ref.read(
        reservationRepositoryProvider,
      );

      // Actualizar únicamente el pago.
      await repository.updateReservationPayment(
        reservationId: reservationId,
        paymentId: paymentId,
      );

      // Actualizar estado del Controller.
      state = const AsyncData(null);

      // Actualizar reservación individual.
      ref.invalidate(
        reservationProvider(reservationId),
      );

      // Actualizar reservaciones del cliente.
      ref.invalidate(
        clientReservationsProvider,
      );
    } catch (error, stackTrace) {
      // Conservar el error en el Controller.
      state = AsyncError(
        error,
        stackTrace,
      );

      rethrow;
    }
  }
}

/// ---------------------------------------------------------------------------
/// Provider del Controller de Reservaciones.
/// ---------------------------------------------------------------------------
final reservationControllerProvider =
AsyncNotifierProvider<ReservationController, void>(
  ReservationController.new,
);