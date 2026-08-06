import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/app/app.dart';

void main() {
  testWidgets('CoachApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CoachApp());

    expect(find.text('Coach App Mobile'), findsOneWidget);
  });
}
