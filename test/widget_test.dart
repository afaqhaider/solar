import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings_onboarding_seen_v1': true,
    });
  });

  testWidgets('App loads to the Dashboard with an empty-project state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SolarCalculatorApp());
    await tester.pumpAndSettle();

    expect(find.text('Solar Dashboard'), findsOneWidget);
    expect(find.text('Plan Your First Solar System'), findsOneWidget);
    expect(find.text('Create Solar Project'), findsWidgets);
  });

  testWidgets('Bottom navigation switches to the Projects tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SolarCalculatorApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Projects').last);
    await tester.pumpAndSettle();

    expect(find.text('No saved projects'), findsOneWidget);
  });

  testWidgets('Creating a project moves to the Loads planner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SolarCalculatorApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Solar Project').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Home Rooftop System');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // The empty-appliances message lives further down the Loads screen than
    // the initial viewport reaches, so scroll it into view before asserting.
    await tester.scrollUntilVisible(find.text('No appliances added'), 300);
    expect(find.text('No appliances added'), findsOneWidget);
  });
}
