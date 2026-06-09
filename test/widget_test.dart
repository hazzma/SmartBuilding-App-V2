// EDIT_TARGET: test/widget_test.dart
// EDIT_PURPOSE: Updates the smoke test to load the current SmartBuildingApp root
// EDIT_REASON: The default counter test referenced a removed MyApp class

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_building_app/app.dart';

void main() {
  testWidgets('Smart Building app renders auth page before login', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartBuildingApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Create account'), findsNothing);
    expect(find.text('Sign Up'), findsNothing);
  });
}
