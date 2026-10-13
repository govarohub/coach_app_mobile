import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/reservation/domain/services/reservation_business_rules.dart';

void main() {
  group('ReservationBusinessRules', () {
    test('validateNoDoubleBooking lanza error si ya existe la reserva', () {
      expect(
        () => ReservationBusinessRules.validateNoDoubleBooking(
          hasExistingReservation: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('formatTimeRange devuelve horario con AM/PM', () {
      expect(
        ReservationBusinessRules.formatTimeRange('08:00', '09:00'),
        '8:00 AM - 9:00 AM',
      );

      expect(
        ReservationBusinessRules.formatTimeRange('13:30', '15:15'),
        '1:30 PM - 3:15 PM',
      );
    });
  });
}
