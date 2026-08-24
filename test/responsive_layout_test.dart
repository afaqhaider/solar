import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar/main.dart';

/// Pumps every primary tab at a range of phone and tablet sizes, in both
/// orientations, and asserts nothing overflows or throws — this is what
/// catches "RenderFlex overflowed" bugs that a single screenshot can miss.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings_onboarding_seen_v1': true,
    });
  });

  final sizes = <String, Size>{
    'small phone portrait': const Size(320, 568),
    'large phone portrait': const Size(430, 932),
    'large phone landscape': const Size(932, 430),
    'tablet portrait': const Size(834, 1194),
    'tablet landscape': const Size(1194, 834),
  };

  for (final entry in sizes.entries) {
    testWidgets('no overflow across all tabs on ${entry.key} (empty state)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(entry.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const SolarCalculatorApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final label in [
        'Loads',
        'Solar',
        'Battery',
        'Inverter',
        'System',
        'Projects',
        'Dashboard',
      ]) {
        final finder = find.text(label).last;
        if (tester.any(finder)) {
          await tester.tap(finder, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'tab "$label" at ${entry.key}',
          );
        }
      }
    });
  }

  testWidgets(
    'no overflow with an active project and an appliance (large phone)',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const SolarCalculatorApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Solar Project').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Test Rooftop');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Add an appliance by filling the form directly (skips the preset dropdown,
      // which opens an overlay route that's awkward to drive in a widget test).
      // Target the FAB specifically — the empty-state card also has an
      // "Add Appliance" label, and only the FAB is guaranteed on-screen.
      await tester.tap(find.byType(FloatingActionButton), warnIfMissed: false);
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Refrigerator'); // name
      await tester.enterText(fields.at(1), '200'); // watts
      await tester.enterText(fields.at(2), '1'); // qty
      await tester.enterText(fields.at(3), '24'); // hours
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final label in [
        'Solar',
        'Battery',
        'Inverter',
        'System',
        'Dashboard',
      ]) {
        await tester.tap(find.text(label).last, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'tab "$label" with data',
        );
      }
    },
  );
}
