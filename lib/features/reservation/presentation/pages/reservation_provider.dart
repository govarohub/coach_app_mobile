import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_state_provider.dart';
import '../../data/datasources/firebase_reservation_datasource.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../../../coach/presentation/pages/coach_schedule_provider.dart';

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
/// ---------------------------------------------------------------------------
final reservationProvider =
FutureProvider.family<Reservation, String>(
      (ref, reservationId) async {
    final repository = ref.watch(
      reservationRepositoryProvider,
    );

    return repository.getReservation(
      reservationId,
    );
  },
);

/// ---------------------------------------------------------------------------
/// Obtiene las reservaciones del cliente autenticado.
/// ---------------------------------------------------------------------------
final clientReservationsProvider =
FutureProvider<List<Reservation>>((ref) async {
  final authState = await ref.watch(
    authStateProvider.future,
  );

  if (authState == null) {
    throw StateError(
      'No existe una sesión de usuario activa.',
    );
  }

  final repository = ref.watch(
    reservationRepositoryProvider,
  );

  return repository.getClientReservations(
    authState.id,
  );
});

/// ---------------------------------------------------------------------------
/// Obtiene las reservaciones de un Coach.
/// ---------------------------------------------------------------------------
final coachReservationsProvider =
FutureProvider.family<List<Reservation>, String>(
      (ref, coachId) async {
    final repository = ref.watch(
      reservationRepositoryProvider,
    );

    return repository.getCoachReservations(
      coachId,
    );
  },
);

/// ---------------------------------------------------------------------------
/// Controller de Reservaciones.
///
/// Responsabilidades:
/// - Obtener el usuario autenticado.
/// - Solicitar al Repository la creación de la reservación.
/// - Mantener el estado loading/error/data de la operación.
///
/// No contiene código de Firestore.
/// ---------------------------------------------------------------------------
class ReservationController extends AsyncNotifier<void> {

  /// ---------------------------------------------------------------------------
  /// CK-016.9
  ///
  /// Completa la operación de reserva del horario.
  ///
  /// Flujo:
  /// 1. Crea la reservación con estado `pending`.
  /// 2. Cambia el horario seleccionado de `available` a `reserved`.
  ///
  /// No procesa pagos ni cambia el estado de la reservación.
  /// ---------------------------------------------------------------------------
  Future<String> createPendingReservationAndReserveSchedule({
    required String coachId,
    required String scheduleId,
    required double amount,
  }) async {
    state = const AsyncLoading();

    try {
      // -------------------------------------------------------------------------
      // 1. Obtener usuario autenticado.
      // -------------------------------------------------------------------------
      final authState = await ref.read(
        authStateProvider.future,
      );

      if (authState == null) {
        throw StateError(
          'No existe una sesión de usuario activa.',
        );
      }

      // -------------------------------------------------------------------------
      // 2. Crear la reservación en estado `pending`.
      //
      // Reutilizamos el método ya validado en CK-016.8.
      // -------------------------------------------------------------------------
      final reservationId = await ref
          .read(reservationRepositoryProvider)
          .createPendingReservation(
        clientId: authState.id,
        coachId: coachId,
        scheduleId: scheduleId,
        amount: amount,
      );

      // -------------------------------------------------------------------------
      // 3. Marcar el horario como reservado.
      // -------------------------------------------------------------------------
      await ref
          .read(coachScheduleRepositoryProvider)
          .updateScheduleStatus(
        scheduleId: scheduleId,
        status: 'reserved',
      );

      // -------------------------------------------------------------------------
      // 4. Actualizar estado del Controller.
      // -------------------------------------------------------------------------
      state = const AsyncData(null);

      // -------------------------------------------------------------------------
      // 5. Actualizar la consulta de horarios.
      // -------------------------------------------------------------------------
      ref.invalidate(
        coachSchedulesProvider(coachId),
      );

      return reservationId;
    } catch (error, stackTrace) {
      // Conservamos el error en el estado del Controller.
      state = AsyncError(
        error,
        stackTrace,
      );

      // Permitimos que la pantalla maneje el error.
      rethrow;
    }
  }

  @override
  Future<void> build() async {}

  /// -------------------------------------------------------------------------
  /// CK-016.8
  ///
  /// Crea una reservación inicial con estado `pending`.
  ///
  /// El clientId se obtiene del usuario autenticado.
  /// La pantalla proporciona:
  /// - coachId
  /// - scheduleId
  /// - amount
  /// -------------------------------------------------------------------------
  Future<String> createPendingReservation({
    required String coachId,
    required String scheduleId,
    required double amount,
  }) async {
    state = const AsyncLoading();

    try {
      // Obtiene el usuario autenticado.
      final authState = await ref.read(
        authStateProvider.future,
      );

      // No se permite crear una reservación sin sesión activa.
      if (authState == null) {
        throw StateError(
          'No existe una sesión de usuario activa.',
        );
      }

      // Obtiene el Repository existente.
      final repository = ref.read(
        reservationRepositoryProvider,
      );

      // Crea la reservación con estado inicial `pending`.
      final reservationId =
      await repository.createPendingReservation(
        clientId: authState.id,
        coachId: coachId,
        scheduleId: scheduleId,
        amount: amount,
      );

      // Actualiza el estado del Controller.
      state = const AsyncData(null);

      // Actualiza las reservaciones del cliente.
      ref.invalidate(
        clientReservationsProvider,
      );

      return reservationId;
    } catch (error, stackTrace) {
      // Conserva el error en el Controller.
      state = AsyncError(
        error,
        stackTrace,
      );

      rethrow;
    }
  }

  /// -------------------------------------------------------------------------
  /// Actualiza el estado de una reservación.
  /// -------------------------------------------------------------------------
  Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
  }) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(
        reservationRepositoryProvider,
      );

      await repository.updateReservationStatus(
        reservationId: reservationId,
        status: status,
      );

      state = const AsyncData(null);

      ref.invalidate(
        reservationProvider(reservationId),
      );

      ref.invalidate(
        clientReservationsProvider,
      );
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );

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
      final repository = ref.read(
        reservationRepositoryProvider,
      );

      await repository.updateReservationPayment(
        reservationId: reservationId,
        paymentId: paymentId,
      );

      state = const AsyncData(null);

      ref.invalidate(
        reservationProvider(reservationId),
      );

      ref.invalidate(
        clientReservationsProvider,
      );
    } catch (error, stackTrace) {
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